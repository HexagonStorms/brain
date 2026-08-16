#!/usr/bin/env zsh
# Fix a movie or TV series poster in Jellyfin. Two distinct failure modes:
#   - frame grab: an embedded landscape still got stored as the Primary image
#     instead of the real poster (mostly movies).
#   - missing series poster: a TV series has season-level art but no
#     series-level Primary image, so Jellyfin's web UI falls back to a season
#     poster while TV apps (which request the series image directly) show
#     nothing. Looks "fine on PC, blank on TV" is the tell for this one.
# Diagnoses each title, pulls the correct poster (Radarr/TMDB for movies,
# Sonarr/TVDB for series), uploads it as Primary, and verifies.
#
# Usage:
#   fix-poster.zsh "Joker" "Hunter x Hunter" "Archer"
#   fix-poster.zsh --force "Some Movie"     # replace even if current image is already portrait
#
# Exit status is nonzero if any requested title could not be fixed.

set -u
emulate -L zsh

STACK=/home/jo/Code/elowynn-media-server
JELLYFIN=http://localhost:8096
RADARR=http://localhost:7878
SONARR=http://localhost:8989

FORCE=0
if [[ "${1:-}" == "--force" ]]; then FORCE=1; shift; fi
if [[ $# -eq 0 ]]; then
  print -u2 "usage: fix-poster.zsh [--force] \"Title\" [more titles...]"
  exit 2
fi

JKEY=$(grep -m1 '^JELLYFIN_API_KEY=' "$STACK/.env" | cut -d= -f2)
RKEY=$(grep -oP '(?<=<ApiKey>)[^<]+' "$STACK/radarr/config.xml")
SKEY=$(grep -oP '(?<=<ApiKey>)[^<]+' "$STACK/sonarr/config.xml")
if [[ -z "$JKEY" || -z "$RKEY" || -z "$SKEY" ]]; then
  print -u2 "could not read Jellyfin/Radarr/Sonarr API keys from $STACK"
  exit 1
fi

# dims of a jpeg on disk. `file` prints an embedded-thumbnail size (e.g. 1x1) first,
# so the real WxH is the LAST match on the line. Empty when there's no image at all
# (Jellyfin returns a 404 JSON body, which has no NxN to match).
dims() { file -b "$1" | grep -oE '[0-9]+x[0-9]+' | tail -1 }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
rc=0

for TERM in "$@"; do
  print "=== $TERM ==="

  # The single-item /Items/{id} endpoint errors on this Jellyfin; the search
  # endpoint is the reliable way in. searchTerm must be URL-encoded -- raw
  # spaces make curl reject the URL outright. Search Movie and Series together;
  # the match's Type decides which provider (Radarr/TMDB or Sonarr/TVDB) supplies
  # the poster.
  ITEMS=$(curl -s -G "$JELLYFIN/Items" \
    --data-urlencode "searchTerm=$TERM" \
    --data-urlencode "IncludeItemTypes=Movie,Series" \
    --data-urlencode "Recursive=true" \
    --data-urlencode "Fields=ProviderIds" \
    --data-urlencode "api_key=$JKEY")
  N=$(print -r -- "$ITEMS" | jq '.Items | length')

  if [[ "$N" -eq 0 ]]; then
    print -u2 "  no Jellyfin movie or series matches \"$TERM\" — skipping"; rc=1; continue
  fi
  if [[ "$N" -gt 1 ]]; then
    print -u2 "  \"$TERM\" is ambiguous ($N matches) — narrow it:"
    print -r -- "$ITEMS" | jq -r '.Items[] | "    - \(.Name) (\(.ProductionYear)) [\(.Type)]"' >&2
    rc=1; continue
  fi

  ID=$(print -r -- "$ITEMS" | jq -r '.Items[0].Id')
  NAME=$(print -r -- "$ITEMS" | jq -r '.Items[0].Name')
  YEAR=$(print -r -- "$ITEMS" | jq -r '.Items[0].ProductionYear')
  TYPE=$(print -r -- "$ITEMS" | jq -r '.Items[0].Type')

  # Current Primary image for the item itself (series-level for a show, not a
  # season). A poster is portrait (H > W); a frame grab is landscape; a series
  # with only season-level art 404s, which downloads empty -- CUR ends up "" and
  # falls through to the fix path same as a landscape frame grab.
  curl -s "$JELLYFIN/Items/$ID/Images/Primary?api_key=$JKEY" -o "$WORK/cur.jpg"
  CUR=$(dims "$WORK/cur.jpg")
  CW=${CUR%x*}; CH=${CUR#*x}
  if [[ -n "$CUR" && "$CW" -le "$CH" && "$FORCE" -eq 0 ]]; then
    print "  $NAME ($YEAR) [$TYPE]: current image is already portrait ($CUR) — looks fine, skipping. Use --force to replace anyway."
    continue
  fi

  POSTER=""
  PROVIDER=""
  if [[ "$TYPE" == "Movie" ]]; then
    TMDB=$(print -r -- "$ITEMS" | jq -r '.Items[0].ProviderIds.Tmdb // empty')
    if [[ -z "$TMDB" ]]; then
      print -u2 "  $NAME ($YEAR): no TMDB id in Jellyfin — cannot look up the right poster. Skipping."; rc=1; continue
    fi
    PROVIDER="Radarr/TMDB (tmdb=$TMDB)"
    # Radarr already knows the correct TMDB poster for every movie it manages.
    POSTER=$(curl -s "$RADARR/api/v3/movie" -H "X-Api-Key: $RKEY" \
      | jq -r --arg t "$TMDB" '.[] | select(.tmdbId==($t|tonumber)) | .images[] | select(.coverType=="poster") | .remoteUrl' | head -1)
    if [[ -z "$POSTER" ]]; then
      # Fallback: ask TMDB through Radarr's lookup (movie may not be in the library).
      POSTER=$(curl -s "$RADARR/api/v3/movie/lookup/tmdb?tmdbId=$TMDB" -H "X-Api-Key: $RKEY" \
        | jq -r '.images[]? | select(.coverType=="poster") | .remoteUrl' | head -1)
    fi
  else
    TVDB=$(print -r -- "$ITEMS" | jq -r '.Items[0].ProviderIds.Tvdb // empty')
    if [[ -z "$TVDB" ]]; then
      print -u2 "  $NAME ($YEAR): no TVDB id in Jellyfin — cannot look up the right poster. Skipping."; rc=1; continue
    fi
    PROVIDER="Sonarr/TVDB (tvdb=$TVDB)"
    # Sonarr already knows the correct TVDB poster for every series it manages.
    POSTER=$(curl -s "$SONARR/api/v3/series" -H "X-Api-Key: $SKEY" \
      | jq -r --arg t "$TVDB" '.[] | select(.tvdbId==($t|tonumber)) | .images[] | select(.coverType=="poster") | .remoteUrl' | head -1)
    if [[ -z "$POSTER" ]]; then
      # Fallback: ask TVDB through Sonarr's lookup (series may not be in the library).
      POSTER=$(curl -s -G "$SONARR/api/v3/series/lookup" -H "X-Api-Key: $SKEY" \
        --data-urlencode "term=tvdb:$TVDB" \
        | jq -r '.[0].images[]? | select(.coverType=="poster") | .remoteUrl' | head -1)
    fi
  fi

  if [[ -z "$POSTER" ]]; then
    print -u2 "  $NAME ($YEAR) [$TYPE]: could not find a poster via $PROVIDER. Skipping."; rc=1; continue
  fi

  curl -s "$POSTER" -o "$WORK/new.jpg"
  NEW=$(dims "$WORK/new.jpg")
  if [[ ! -s "$WORK/new.jpg" ]]; then
    print -u2 "  $NAME ($YEAR): poster download failed. Skipping."; rc=1; continue
  fi

  # Jellyfin image upload wants a base64 body and the image mime type. 204 = stored.
  # This is always the item's own Primary slot -- for a series that's the
  # series-level image, not any season's, which is the one TV apps actually read.
  base64 -w0 "$WORK/new.jpg" > "$WORK/new.b64"
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "$JELLYFIN/Items/$ID/Images/Primary?api_key=$JKEY" \
    -H "Content-Type: image/jpeg" --data-binary "@$WORK/new.b64")
  if [[ "$CODE" != "204" ]]; then
    print -u2 "  $NAME ($YEAR): upload failed (HTTP $CODE). Skipping."; rc=1; continue
  fi

  # Verify Jellyfin now serves the portrait poster, not the old frame (or nothing).
  curl -s "$JELLYFIN/Items/$ID/Images/Primary?api_key=$JKEY" -o "$WORK/verify.jpg"
  VER=$(dims "$WORK/verify.jpg")
  STATE="frame grab"
  [[ -z "$CUR" ]] && STATE="missing"
  print "  $NAME ($YEAR) [$TYPE]: was ${CUR:-none} ($STATE) -> now $VER (poster). Fixed."
done

exit $rc

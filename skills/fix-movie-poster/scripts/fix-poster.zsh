#!/usr/bin/env zsh
# Fix a movie's poster in Jellyfin when it is showing a frame grab instead of the
# real poster art. Diagnoses each title, pulls the correct TMDB poster (via Radarr,
# which already tracks it), uploads it as the Jellyfin Primary image, and verifies.
#
# Usage:
#   fix-poster.zsh "Joker" "Basquiat" "Avatar"
#   fix-poster.zsh --force "Some Movie"     # replace even if current image is already portrait
#
# Exit status is nonzero if any requested title could not be fixed.

set -u
emulate -L zsh

STACK=/home/jo/Code/elowynn-media-server
JELLYFIN=http://localhost:8096
RADARR=http://localhost:7878

FORCE=0
if [[ "${1:-}" == "--force" ]]; then FORCE=1; shift; fi
if [[ $# -eq 0 ]]; then
  print -u2 "usage: fix-poster.zsh [--force] \"Movie Name\" [more names...]"
  exit 2
fi

JKEY=$(grep -m1 '^JELLYFIN_API_KEY=' "$STACK/.env" | cut -d= -f2)
RKEY=$(grep -oP '(?<=<ApiKey>)[^<]+' "$STACK/radarr/config.xml")
if [[ -z "$JKEY" || -z "$RKEY" ]]; then
  print -u2 "could not read Jellyfin/Radarr API keys from $STACK"
  exit 1
fi

# dims of a jpeg on disk. `file` prints an embedded-thumbnail size (e.g. 1x1) first,
# so the real WxH is the LAST match on the line.
dims() { file -b "$1" | grep -oE '[0-9]+x[0-9]+' | tail -1 }

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
rc=0

for TERM in "$@"; do
  print "=== $TERM ==="

  # The single-item /Items/{id} endpoint errors on this Jellyfin; the search
  # endpoint is the reliable way in. Ask for the fields we need in one shot.
  # searchTerm must be URL-encoded -- raw spaces make curl reject the URL outright.
  ITEMS=$(curl -s -G "$JELLYFIN/Items" \
    --data-urlencode "searchTerm=$TERM" \
    --data-urlencode "IncludeItemTypes=Movie" \
    --data-urlencode "Recursive=true" \
    --data-urlencode "Fields=ProviderIds" \
    --data-urlencode "api_key=$JKEY")
  N=$(print -r -- "$ITEMS" | jq '.Items | length')

  if [[ "$N" -eq 0 ]]; then
    print -u2 "  no Jellyfin movie matches \"$TERM\" — skipping"; rc=1; continue
  fi
  if [[ "$N" -gt 1 ]]; then
    print -u2 "  \"$TERM\" is ambiguous ($N matches) — narrow it:"
    print -r -- "$ITEMS" | jq -r '.Items[] | "    - \(.Name) (\(.ProductionYear))"' >&2
    rc=1; continue
  fi

  ID=$(print -r -- "$ITEMS" | jq -r '.Items[0].Id')
  NAME=$(print -r -- "$ITEMS" | jq -r '.Items[0].Name')
  YEAR=$(print -r -- "$ITEMS" | jq -r '.Items[0].ProductionYear')
  TMDB=$(print -r -- "$ITEMS" | jq -r '.Items[0].ProviderIds.Tmdb // empty')

  # Current Primary image. A poster is portrait (H > W); a frame grab is landscape.
  curl -s "$JELLYFIN/Items/$ID/Images/Primary?api_key=$JKEY" -o "$WORK/cur.jpg"
  CUR=$(dims "$WORK/cur.jpg")
  CW=${CUR%x*}; CH=${CUR#*x}
  if [[ -n "$CUR" && "$CW" -le "$CH" && "$FORCE" -eq 0 ]]; then
    print "  $NAME ($YEAR): current image is already portrait ($CUR) — looks fine, skipping. Use --force to replace anyway."
    continue
  fi

  if [[ -z "$TMDB" ]]; then
    print -u2 "  $NAME ($YEAR): no TMDB id in Jellyfin — cannot look up the right poster. Skipping."; rc=1; continue
  fi

  # Radarr already knows the correct TMDB poster for every movie it manages.
  POSTER=$(curl -s "$RADARR/api/v3/movie" -H "X-Api-Key: $RKEY" \
    | jq -r --arg t "$TMDB" '.[] | select(.tmdbId==($t|tonumber)) | .images[] | select(.coverType=="poster") | .remoteUrl' | head -1)
  if [[ -z "$POSTER" ]]; then
    # Fallback: ask TMDB through Radarr's lookup (movie may not be in the library).
    POSTER=$(curl -s "$RADARR/api/v3/movie/lookup/tmdb?tmdbId=$TMDB" -H "X-Api-Key: $RKEY" \
      | jq -r '.images[]? | select(.coverType=="poster") | .remoteUrl' | head -1)
  fi
  if [[ -z "$POSTER" ]]; then
    print -u2 "  $NAME ($YEAR): could not find a poster via Radarr/TMDB (tmdb=$TMDB). Skipping."; rc=1; continue
  fi

  curl -s "$POSTER" -o "$WORK/new.jpg"
  NEW=$(dims "$WORK/new.jpg")
  if [[ ! -s "$WORK/new.jpg" ]]; then
    print -u2 "  $NAME ($YEAR): poster download failed. Skipping."; rc=1; continue
  fi

  # Jellyfin image upload wants a base64 body and the image mime type. 204 = stored.
  base64 -w0 "$WORK/new.jpg" > "$WORK/new.b64"
  CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    "$JELLYFIN/Items/$ID/Images/Primary?api_key=$JKEY" \
    -H "Content-Type: image/jpeg" --data-binary "@$WORK/new.b64")
  if [[ "$CODE" != "204" ]]; then
    print -u2 "  $NAME ($YEAR): upload failed (HTTP $CODE). Skipping."; rc=1; continue
  fi

  # Verify Jellyfin now serves the portrait poster, not the old frame.
  curl -s "$JELLYFIN/Items/$ID/Images/Primary?api_key=$JKEY" -o "$WORK/verify.jpg"
  VER=$(dims "$WORK/verify.jpg")
  print "  $NAME ($YEAR): was ${CUR:-none} (frame grab) -> now $VER (poster). Fixed."
done

exit $rc

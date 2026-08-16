#!/usr/bin/env python3
"""Prune above-4K photos from a creator's grabbed gallery.

Policy (Jo, 2026-07-20): a big gallery does not need giant masters. If a
creator's photo folder holds >= KEEP_ALL_UNDER photos, drop every photo whose
longest edge is > MAX_EDGE px (i.e. "above 4K"), keeping only the 4K-and-under
set. Small galleries (< KEEP_ALL_UNDER) are left fully intact.

No third-party deps: JPEG/PNG dimensions are read straight from the file header,
so this runs on elowynn's bare python3 (no PIL/imagemagick).

Usage:
  python3 prune-oversized.py "<creator>"            # prune per policy
  python3 prune-oversized.py "<creator>" --dry-run  # report only, delete nothing
  python3 prune-oversized.py --dir "/abs/path"      # target a folder directly

After a real prune, run Stash's "Clean" library task so the DB drops the image
records that now point at deleted files.
"""
import os, struct, sys

MAX_EDGE = 3840        # longest edge <= this is "4K or lower" -> keep
KEEP_ALL_UNDER = 250   # galleries smaller than this keep every photo
BASE = "/media/data/stash/Unsorted/onlyfans"
EXTS = (".jpg", ".jpeg", ".png")


def jpeg_size(f):
    if f.read(2) != b"\xff\xd8":
        return None
    while True:
        b = f.read(1)
        while b and b != b"\xff":
            b = f.read(1)
        marker = f.read(1)
        while marker == b"\xff":
            marker = f.read(1)
        if not marker:
            return None
        m = marker[0]
        if m in (0xC0,0xC1,0xC2,0xC3,0xC5,0xC6,0xC7,0xC9,0xCA,0xCB,0xCD,0xCE,0xCF):
            f.read(3)
            h, w = struct.unpack(">HH", f.read(4))
            return w, h
        if m in (0xD8, 0xD9) or 0xD0 <= m <= 0xD7:
            continue
        seg = f.read(2)
        if len(seg) < 2:
            return None
        f.seek(struct.unpack(">H", seg)[0] - 2, 1)


def png_size(f):
    if f.read(8) != b"\x89PNG\r\n\x1a\n":
        return None
    f.read(4)  # IHDR length
    if f.read(4) != b"IHDR":
        return None
    w, h = struct.unpack(">II", f.read(8))
    return w, h


def dims(path):
    with open(path, "rb") as f:
        head = f.read(1)
        f.seek(0)
        if head == b"\x89":
            return png_size(f)
        return jpeg_size(f)


def human(n):
    for u in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024:
            return f"{n:.2f} {u}"
        n /= 1024
    return f"{n:.2f} PB"


def main(argv):
    dry = "--dry-run" in argv
    argv = [a for a in argv if a != "--dry-run"]
    if "--dir" in argv:
        d = argv[argv.index("--dir") + 1]
        label = os.path.basename(d.rstrip("/"))
    elif argv:
        label = argv[0]
        d = os.path.join(BASE, f"{label} (photos)")
    else:
        print("usage: prune-oversized.py <creator> [--dry-run] | --dir <path>")
        return 2

    if not os.path.isdir(d):
        print(f"no such folder: {d}")
        return 1

    files = [os.path.join(d, x) for x in os.listdir(d) if x.lower().endswith(EXTS)]
    n = len(files)
    if n < KEEP_ALL_UNDER:
        print(f"{label}: {n} photos (< {KEEP_ALL_UNDER}) -> keep all, nothing to do")
        return 0

    del_n = del_b = unk = err = 0
    for p in files:
        try:
            dim = dims(p)
        except Exception:
            dim = None
        if dim is None:
            unk += 1  # unmeasurable -> keep (safe)
            continue
        if max(dim) > MAX_EDGE:
            sz = os.path.getsize(p)
            if dry:
                del_n += 1; del_b += sz
            else:
                try:
                    os.remove(p); del_n += 1; del_b += sz
                except Exception as e:
                    err += 1; print("ERR", p, e)

    verb = "would delete" if dry else "deleted"
    print(f"{label}: {n} photos; {verb} {del_n} above-{MAX_EDGE}px "
          f"({100*del_n/n:.1f}%), freed {human(del_b)}"
          + (f", unmeasurable(kept) {unk}" if unk else "")
          + (f", errors {err}" if err else ""))
    if not dry and del_n:
        print("  -> run Stash 'Clean' task to drop DB records for the removed files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))

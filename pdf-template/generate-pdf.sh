#!/bin/bash
# Markdown -> PDF via pandoc (gfm) + headless Edge print-to-pdf.
# Reproduces the exact look of 課題20260829.pdf / 課題20260903.pdf
# (GitHub-style [!NOTE]/[!TIP] boxes, Meiryo-based font stack, no page numbers).
#
# Usage: ./generate-pdf.sh <input.md> [output.pdf]
# If output.pdf is omitted, it defaults to <input-basename>.pdf next to the input file.

set -euo pipefail

PANDOC="/c/Users/seiji/AppData/Local/Pandoc/pandoc.exe"
EDGE="/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe"
TEMPLATE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MD_PATH="${1:?Usage: generate-pdf.sh <input.md> [output.pdf]}"
MD_DIR="$(cd "$(dirname "$MD_PATH")" && pwd)"
MD_BASENAME="$(basename "$MD_PATH")"
MD_NAME="${MD_BASENAME%.*}"
OUT_PATH="${2:-$MD_DIR/$MD_NAME.pdf}"

# Build the work dir under the real Windows temp path (not git-bash's internal
# /tmp) so that "file://$WORK/..." URLs are actually resolvable by msedge.exe.
WORK="$HOME/AppData/Local/Temp/pdfgen_$$_$(date +%s)"
mkdir -p "$WORK"
# Edge's headless launcher can leave a child process briefly holding profile
# files open after we've already read the finished PDF, so a bare "rm -rf"
# here can fail with "Device or resource busy" and (with set -e) clobber an
# otherwise-successful run's exit code. Retry once, then give up quietly -
# it's a throwaway temp dir either way.
cleanup() {
  rm -rf "$WORK" 2>/dev/null || { sleep 2; rm -rf "$WORK" 2>/dev/null || true; }
}
trap cleanup EXIT

# 1. Markdown -> HTML fragment (pandoc's gfm reader natively turns
#    > [!NOTE] / [!TIP] blockquotes into <div class="note">/<div class="tip">,
#    matching the CSS in header.html).
"$PANDOC" -f gfm+fenced_divs -t html --wrap=preserve "$MD_DIR/$MD_BASENAME" -o "$WORK/body.html"

# 2. Fill in the header template (title + base href for relative image/link paths).
WIN_MD_DIR="$(cd "$MD_DIR" && pwd -W 2>/dev/null || echo "$MD_DIR" | sed 's|^/\([a-zA-Z]\)/|\1:/|')"
BASE_HREF="file:///${WIN_MD_DIR}/"
sed -e "s|__TITLE__|${MD_NAME}|g" -e "s|__BASEDIR__|${BASE_HREF}|g" \
    "$TEMPLATE_DIR/header.html" > "$WORK/header.html"

# 3. Concatenate header + body + footer.
cat "$WORK/header.html" "$WORK/body.html" "$TEMPLATE_DIR/footer.html" > "$WORK/full.html"

# git-bash's MSYS layer silently mangles "/c/..."-style paths when they're
# embedded inside a larger argument string like a file:// URI (as opposed to
# being the whole argument, which it converts correctly) - this breaks
# navigation with ERR_FILE_NOT_FOUND. Using the explicit C:/... form for the
# URI sidesteps that path-conversion heuristic entirely.
WIN_WORK="$(cd "$WORK" && pwd -W)"
FULL_HTML_URI="file:///${WIN_WORK}/full.html"

# 4. Print to PDF with a throwaway Edge profile (avoids clobbering the user's
#    real browser session and avoids lock conflicts with any other Edge windows).
#    Written to a temp path first so a failed render never clobbers an existing
#    good PDF at $OUT_PATH.
PROFILE_DIR="$WORK/profile"
mkdir -p "$PROFILE_DIR"
DRAFT_PATH="$WORK/draft.pdf"

"$EDGE" --headless --disable-gpu --no-first-run --no-default-browser-check \
  --disable-extensions --disable-sync \
  --user-data-dir="$PROFILE_DIR" \
  --no-pdf-header-footer \
  --print-to-pdf="$DRAFT_PATH" \
  "$FULL_HTML_URI" > "$WORK/edge.log" 2>&1 || true

# 5. Chromium's headless launcher can return before the background render
#    finishes writing the file, so poll until the output size stabilizes.
elapsed=0
last_size=-1
stable=0
while [ "$elapsed" -lt 90 ]; do
  if [ -f "$DRAFT_PATH" ]; then
    size=$(stat -c%s "$DRAFT_PATH" 2>/dev/null || echo 0)
    if [ "$size" = "$last_size" ] && [ "$size" -gt 0 ]; then
      stable=$((stable + 1))
      if [ "$stable" -ge 2 ]; then break; fi
    else
      stable=0
    fi
    last_size="$size"
  fi
  sleep 1
  elapsed=$((elapsed + 1))
done

if [ ! -f "$DRAFT_PATH" ]; then
  echo "ERROR: PDF was not created." >&2
  cat "$WORK/edge.log" >&2
  exit 1
fi

final_size=$(stat -c%s "$DRAFT_PATH")
if [ "$final_size" -lt 150000 ]; then
  echo "ERROR: output PDF looks like a failed render ($final_size bytes) -" >&2
  echo "likely an ERR_FILE_NOT_FOUND error page instead of real content." >&2
  cp "$DRAFT_PATH" "${OUT_PATH%.pdf}_FAILED.pdf"
  echo "Left the failed draft at: ${OUT_PATH%.pdf}_FAILED.pdf for inspection." >&2
  exit 1
fi

mv -f "$DRAFT_PATH" "$OUT_PATH"
echo "Created: $OUT_PATH ($final_size bytes)"

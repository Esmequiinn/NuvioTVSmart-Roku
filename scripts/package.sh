#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_ZIP="${1:-/tmp/nuvio-roku-dev.zip}"

rm -f "$OUT_ZIP"
(
    cd "$ROOT_DIR"
    zip -rq "$OUT_ZIP" \
        manifest \
        source \
        components \
        images \
        assets \
        locale \
        web \
        -x "*/.DS_Store" "*.git*" "docs/*" "tests/*" "scripts/*"
)

echo "Packaged clean Roku sideload archive: $OUT_ZIP"
ls -lh "$OUT_ZIP"

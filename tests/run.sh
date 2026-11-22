#!/bin/sh
# Runs the notWebReady regression twice: against the base ref (must FAIL, because
# the base does not mark the stream) and against the working tree (must PASS).
#
# Usage: tests/run.sh [/path/to/brs] [base-ref]
#
# The base defaults to origin/main. The tricky part is Playback.brs: brs 0.45 has
# no try/catch, so the wrapper keywords are stripped before the file is parsed.
set -e

BRS=${1:-brs}
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

BASE=${2:-origin/main}
if ! git rev-parse --verify --quiet "$BASE" >/dev/null 2>&1; then
    echo "ERROR: no existe la referencia $BASE" >&2
    exit 1
fi

RUNROOT=$(mktemp -d)
BEFORE=$(mktemp -d)
trap 'rm -rf "$RUNROOT" "$BEFORE"' EXIT INT TERM
ln -s "$ROOT/tests" "$RUNROOT/tests"

sanitize_playback() {
    sed -E '/^[[:space:]]*(try|catch([[:space:]].*)?|end[[:space:]]+try)[[:space:]]*$/d'
}

WEBCOMMON="components/I18n.brs components/Util.brs"
WEBTEST="tests/test_notwebready_stream.brs"

echo "== referencia base: $BASE =="
git show "$BASE:components/Streams.brs" > "$BEFORE/Streams.brs"
git show "$BASE:components/Playback.brs" | sanitize_playback > "$BEFORE/Playback.brs"
sanitize_playback < components/Playback.brs > "$BEFORE/Playback.after.brs"

echo
echo "== antes del parche (Streams.brs y Playback.brs de $BASE) =="
set +e
"$BRS" -r "$RUNROOT" $WEBCOMMON "$BEFORE/Streams.brs" "$BEFORE/Playback.brs" "$WEBTEST" > "$BEFORE/before.log" 2>&1
set -e
cat "$BEFORE/before.log"

echo
echo "== despues del parche (working tree) =="
"$BRS" -r "$RUNROOT" $WEBCOMMON components/Streams.brs "$BEFORE/Playback.after.brs" "$WEBTEST" > "$BEFORE/after.log" 2>&1
cat "$BEFORE/after.log"

status=0
if grep -q "^RESULT: FAIL (" "$BEFORE/before.log"; then
    echo
    echo "OK: el test falla sin el parche"
else
    echo
    echo "ERROR: el test no falla sin el parche"
    status=1
fi
if grep -q "^RESULT: PASS (" "$BEFORE/after.log"; then
    echo "OK: el test pasa con el parche"
else
    echo "ERROR: el test no pasa con el parche"
    status=1
fi
exit $status

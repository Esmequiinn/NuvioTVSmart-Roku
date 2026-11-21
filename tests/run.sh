#!/bin/sh
# Runs the required-extra regression test twice: against the current working
# tree (must PASS) and against the same CatalogTask.brs as committed in HEAD
# (must FAIL). The "before" run is reconstructed from git, so nothing has to be
# stashed or reverted.
#
# Usage:  tests/run.sh [/path/to/brs] [base-ref]
#
# Requires the `brs` BrightScript interpreter (npm package "brs"). The repo has
# no test runner, so the interpreter is supplied from outside the checkout; this
# script does not add any dependency to the project.

set -e

BRS=${1:-brs}
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

# `brs -r` also loads <root>/components/**/*.xml, and part of the SceneGraph
# sources uses syntax this interpreter does not parse, so run with a minimal
# root that only exposes the fixtures through pkg:/.
RUNROOT=$(mktemp -d)
BEFORE=$(mktemp -d)
trap 'rm -rf "$RUNROOT" "$BEFORE"' EXIT INT TERM
ln -s "$ROOT/tests" "$RUNROOT/tests"

# Read-only, non-SceneGraph script files needed to execute CatalogTask.brs.
COMMON="components/I18n.brs components/Util.brs components/Store.brs components/Content.brs components/Addon.brs components/Http.brs components/ServerRows.brs"
TEST="tests/test_required_extra_catalog.brs"

# El "antes" sale de la rama base, no de HEAD: en un PR el fix ya esta commiteado
# y comparar contra HEAD daria PASS en las dos corridas.
BASE=${2:-origin/main}
if ! git rev-parse --verify --quiet "$BASE" >/dev/null 2>&1; then
    BASE=main
fi
echo "== referencia base: $BASE =="
git show "$BASE:components/tasks/CatalogTask.brs" > "$BEFORE/CatalogTask.brs"

echo "== antes del parche (CatalogTask.brs de $BASE) =="
set +e
"$BRS" -r "$RUNROOT" $COMMON "$BEFORE/CatalogTask.brs" "$TEST" > "$BEFORE/out.log" 2>&1
set -e
cat "$BEFORE/out.log"

echo
echo "== despues del parche (working tree) =="
"$BRS" -r "$RUNROOT" $COMMON components/tasks/CatalogTask.brs "$TEST" > "$BEFORE/after.log" 2>&1
cat "$BEFORE/after.log"

status=0
if grep -q "^RESULT: FAIL (" "$BEFORE/out.log"; then
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

#!/usr/bin/env bash
# Run every headless native test and list the ones that fail.
# check.sh stops at the first failing file, so use this to see every failure at once after a broad change.
set -uo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: bash scripts/sweep_tests.sh [jobs] [name-filter]"
    echo "Runs tests/native/*_test.gd (except *_visual_test.gd) headless, 'jobs' at a time (default 4)."
    echo "Each log goes to internal/verification/sweep/<test>.log; failures are rerun alone to rule out interference."
    echo "Example: bash scripts/sweep_tests.sh 6 town"
    exit 0
fi
jobs="${1:-4}"
filter="${2:-}"
logs="$project_dir/internal/verification/sweep"
rm -rf "$logs"
mkdir -p "$logs"
timeout 300 bash scripts/play.sh --headless --import > "$logs/import.log" 2>&1
run_one() {
    local name="$1" log="$2/$1.log"
    timeout 240 bash scripts/play.sh --headless --script "../../tests/native/$name.gd" > "$log" 2>&1
    local status=$?
    if [[ $status -ne 0 ]] || grep -qE 'SCRIPT ERROR:|^ERROR:|^WARNING:|FAIL:|out of memory' "$log"; then
        echo "$name"
    fi
}
export -f run_one
tests=$(ls tests/native/*_test.gd | xargs -n1 basename | sed 's/\.gd$//' | grep -vE '(^|_)visual_test$' | grep -- "$filter")
echo "$(echo "$tests" | wc -l) tests, $jobs at a time"
suspects=$(echo "$tests" | xargs -P "$jobs" -I{} bash -c 'run_one "$@"' _ {} "$logs" | sort)
failed=""
for name in $suspects; do
    failed+=$(run_one "$name" "$logs")$'\n'
done
failed=$(echo "$failed" | sed '/^$/d')
if [[ -z "$failed" ]]; then
    echo "All passed. Logs: $logs"
    exit 0
fi
echo "Failed:"
for name in $failed; do
    echo "  $name: $(grep -m1 -E 'FAIL:|SCRIPT ERROR:|^ERROR:|^WARNING:|out of memory' "$logs/$name.log" | cut -c1-160)"
done
echo "Logs: $logs"
exit 1

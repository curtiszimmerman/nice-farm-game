#!/usr/bin/env bash
# Run the native prototype's headless checks without installing dependencies.
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_dir"
if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: bash scripts/check.sh"
    echo "Check shell syntax, simulation, native interactions, persistence, and scene startup."
    exit 0
fi
bash -n scripts/play.sh scripts/check.sh
for test_file in state_test integration_test save_test; do
    bash scripts/play.sh --headless --script "../../tests/native/$test_file.gd"
done
bash scripts/play.sh --headless -- --smoke-test

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
for test_file in state_test integration_test save_test audio_test development_test readability_test outcrop_test grid_test schedule_test landscape_test geography_test interior_test inventory_test interior_layout_test farming_chest_test conversation_test interior_depth_test supplies_test ship_ui_test starting_supplies_test arrival_test welcome_sequence_test fishing_species_test cave_test render_layers_test; do
    bash scripts/play.sh --headless --script "../../tests/native/$test_file.gd"
done
bash scripts/play.sh --headless -- --smoke-test

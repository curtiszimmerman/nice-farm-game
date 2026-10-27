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
python3 -B tests/test_sprite_assets.py
python3 -B tests/test_border_surfaces.py
python3 -B tests/test_terrain_edges.py
mkdir -p internal/verification
run_native() {
    local check_log="$project_dir/internal/verification/check-current.log"
    if timeout 120 bash scripts/play.sh "$@" > "$check_log" 2>&1; then
        cat "$check_log"
    else
        cat "$check_log"
        return 1
    fi
    if rg -q 'SCRIPT ERROR:|^ERROR:|^WARNING:|FAIL:' "$check_log"; then
        return 1
    fi
}
for test_file in player_status_test status_hud_test bread_shop_test cave_spider_test cave_resources_test crucible_test construction_test interaction_footprint_test shop_continuity_test welcome_queue_test watered_growth_test weather_test inventory_order_test storage_drag_test facing_interaction_test character_screen_test combat_feedback_test cutscene_hud_test battle_audio_test house_circulation_test tool_facing_test pause_sources_test farmhouse_revision_test cave_arrival_test tool_motion_test wall_width_test observatory_test town_lighting_test calendar_test route_stability_test quest_log_test town_paths_test interior_revision_test tool_sources_test npc_priority_test action_controls_test neighbors_test intro_pacing_test active_item_test welcome_walk_test coast_test firewood_test randomization_test npc_transition_test hud_pause_test art_pack_test rustic_art_test crew_flow_test art_test; do
    run_native --headless --script "../../tests/native/$test_file.gd"
done
for test_file in action_balance_test action_town_revision_test observatory_hours_test garden_tending_test local_requests_state_test weekly_board_test local_guidance_test weekly_board_dialogue_test; do
    run_native --headless --script "../../tests/native/$test_file.gd"
done
for test_file in audit_regressions_test unrestricted_watering_test seasonal_forage_test bell_ladder_test state_test integration_test save_test audio_test development_test readability_test outcrop_test grid_test schedule_test landscape_test geography_test interior_test inventory_test interior_layout_test farming_chest_test conversation_test interior_depth_test supplies_test ship_ui_test starting_supplies_test arrival_test welcome_sequence_test fishing_species_test cave_test render_layers_test; do
    run_native --headless --script "../../tests/native/$test_file.gd"
done
run_native --headless --script "../../tests/native/dialogue_weather_revision_test.gd"
run_native --headless --script "../../tests/native/cave_opening_art_test.gd"
for test_file in terrain_borders_test border_atlas_test terrain_art_integration_test town_life_state_test town_life_rules_test town_life_world_test town_life_content_test tavern_life_test calendar_transition_test spell_lessons_test cave_levels_test town_icons_test partial_pack_test; do
    run_native --headless --script "../../tests/native/$test_file.gd"
done
run_native --headless -- --smoke-test
for test_file in supply_dialogue_revision_test hardcore_needs_test journey_mode_test weekday_magic_test social_days_test berry_kitchen_test seasonal_weather_test farm_radius_test farm_radius_world_test temple_service_test temple_complex_test cave_generation_variation_test; do
    run_native --headless --script "../../tests/native/$test_file.gd"
done

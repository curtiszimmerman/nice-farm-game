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
# Running a script doesn't reimport changed assets, so regenerated art would otherwise be tested from Godot's stale cache.
timeout 300 bash scripts/play.sh --headless --import > internal/verification/import.log 2>&1
run_native() {
    local check_log="$project_dir/internal/verification/check-current.log"
    if timeout 120 bash scripts/play.sh "$@" > "$check_log" 2>&1; then
        cat "$check_log"
    else
        cat "$check_log"
        return 1
    fi
    if grep -qE 'SCRIPT ERROR:|^ERROR:|^WARNING:|FAIL:' "$check_log"; then
        return 1
    fi
}
run_native --headless --script "../../tests/native/welcome_polish_test.gd"
for test_file in dialogue_feedback_test feedback_systems_test landscape_feedback_test npc_push_chain_test shop_wallet_test; do
    run_native --headless --script "../../tests/native/$test_file.gd"
done
run_native --headless --script "../../tests/native/ship_bridge_test.gd"
run_native --headless --script "../../tests/native/bridge_ambience_test.gd"
run_native --headless --script "../../tests/native/attacker_reveal_test.gd"
run_native --headless --script "../../tests/native/shutdown_playback_test.gd"
run_native --headless --script "../../tests/native/first_departure_music_test.gd"
run_native --headless --script "../../tests/native/occlusion_test.gd"
run_native --headless --script "../../tests/native/building_depth_test.gd"
run_native --headless --script "../../tests/native/town_streets_test.gd"
run_native --headless --script "../../tests/native/village_traffic_test.gd"
run_native --headless --script "../../tests/native/rain_shelter_test.gd"
run_native --headless --script "../../tests/native/beach_test.gd"
run_native --headless --script "../../tests/native/forage_feedback_test.gd"
run_native --headless --script "../../tests/native/escape_closes_window_test.gd"
run_native --headless --script "../../tests/native/vale_repairs_test.gd"
run_native --headless --script "../../tests/native/replicator_priority_test.gd"
run_native --headless --script "../../tests/native/house_facades_test.gd"
run_native --headless --script "../../tests/native/viewport_zoom_test.gd"
run_native --headless --script "../../tests/native/newcomers_test.gd"
run_native --headless --script "../../tests/native/curio_shop_test.gd"
run_native --headless --script "../../tests/native/smith_metals_test.gd"
run_native --headless --script "../../tests/native/ship_bulkhead_depth_test.gd"
run_native --headless --script "../../tests/native/stable_scenery_depth_test.gd"
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
run_native --headless --script "../../tests/native/rift_forecast_test.gd"
run_native --headless --script "../../tests/native/iona_prerequisites_test.gd"
for test_file in production_soil_revision_test shop_hold_test rain_beach_test npc_dialogue_polish_test town_systems_revision_test npc_route_policy_test lore_guidance_revision_test; do
    run_native --headless --script "../../tests/native/$test_file.gd"
done
run_native --headless -- --smoke-test
for test_file in supply_dialogue_revision_test hardcore_needs_test journey_mode_test weekday_magic_test social_days_test berry_kitchen_test seasonal_weather_test farm_radius_test farm_radius_world_test temple_service_test temple_complex_test cave_generation_variation_test latest_feedback_test dialogue_flow_polish_test new_crops_test crop_shop_test npc_passing_test square_garden_revision_test shop_performance_revision_test farm_art_test plot_decay_test tool_sounds_test; do
    run_native --headless --script "../../tests/native/$test_file.gd"
done

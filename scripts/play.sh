#!/usr/bin/env bash
# Launch the native Godot game with all writable runtime paths inside this project.
set -euo pipefail
project_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ "${1:-}" == "--help" ]]; then
    echo "Usage: bash scripts/play.sh [Godot arguments]"
    echo "Launch the native first-landing game. All saves, logs, and caches stay in internal/."
    echo "Example: bash scripts/play.sh --headless --quit-after 5"
    exit 0
fi
engine="$project_dir/vendor/godot/Godot_v4.5.1-stable_linux.x86_64"
if [[ ! -x "$engine" ]]; then
    echo "Native Godot executable is missing: $engine" >&2
    echo "See docs/PLAY.md for the pinned engine location." >&2
    exit 1
fi
export XDG_DATA_HOME="$project_dir/internal/runtime/data"
export XDG_CONFIG_HOME="$project_dir/internal/runtime/config"
export XDG_CACHE_HOME="$project_dir/internal/runtime/cache"
export TMPDIR="$project_dir/internal/runtime/tmp"
export __GL_SHADER_DISK_CACHE_PATH="$project_dir/internal/runtime/cache/nvidia"
export MESA_SHADER_CACHE_DIR="$project_dir/internal/runtime/cache/mesa"
mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$TMPDIR" "$__GL_SHADER_DISK_CACHE_PATH" "$MESA_SHADER_CACHE_DIR"
exec "$engine" --path "$project_dir/src/native" "$@"

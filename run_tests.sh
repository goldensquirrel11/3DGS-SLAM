#!/bin/bash
#
# Runs the system-tests
#
# Usage:
#   ./run_tests.sh            # stage 1-2 tests only (CPU, fast, default)
#   ./run_tests.sh --gpu      # also run the stage 3-4 end-to-end system
#                              # test (needs CUDA + a display/xvfb-run)
#
# Env vars (all optional):
#   ENV_NAME     conda environment to activate (default: rgbd-3dgs-slam)
#   MONOGS_DIR   path to the MonoGS checkout   (default: ./MonoGS)
#   ROS_WS_DIR   path to the ros_ws checkout   (default: ../ros_ws)

set -u

ENV_NAME="${ENV_NAME:-rgbd-3dgs-slam}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MONOGS_DIR="${MONOGS_DIR:-$SCRIPT_DIR/MonoGS}"
ROS_WS_DIR="${ROS_WS_DIR:-$SCRIPT_DIR/../ros_ws}"

RUN_GPU_TEST=false
if [[ "${1:-}" == "--gpu" ]]; then
    RUN_GPU_TEST=true
fi

FAILED=()

echo "== Activating conda env: $ENV_NAME =="
# conda's own activation scripts aren't nounset-safe; relax -u around them.
set +u
eval "$(conda shell.bash hook)"
conda activate "$ENV_NAME" || { echo "Could not activate conda env '$ENV_NAME'"; exit 1; }
set -u

run_step() {
    local name="$1"
    shift
    echo
    echo "== $name =="
    if "$@"; then
        echo "-- PASSED: $name --"
    else
        echo "-- FAILED: $name --"
        FAILED+=("$name")
    fi
}

# --- MonoGS ROSDataset ingestion + transform tests (CPU) ---
run_step "MonoGS stage 1-2 tests" bash -c "
    cd '$MONOGS_DIR' &&
    PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 pytest tests/ --ignore=tests/system -v
"

# --- video_publisher calibration parsing (CPU) ---
run_step "video_publisher calibration parsing tests" bash -c "
    cd '$ROS_WS_DIR' &&
    PYTHONPATH=\"src/video_publisher:\${PYTHONPATH:-}\" \
        PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 pytest src/video_publisher/test/test_camera_calibration_parsing.py -v
"

# --- video_publisher functional test (real node, via launch_test) ---
run_step "video_publisher functional test" bash -c "
    cd '$ROS_WS_DIR' &&
    colcon build --symlink-install --packages-select video_publisher &&
    source install/setup.bash &&
    PYTHONPATH=\"src/video_publisher/test:\${PYTHONPATH:-}\" \
        launch_test src/video_publisher/test/test_camera_functional.py -v
"

# --- end-to-end live pipeline (GPU required) ---
if [[ "$RUN_GPU_TEST" == true ]]; then
    run_step "MonoGS stage 3-4 end-to-end system test" bash -c "
        cd '$MONOGS_DIR' &&
        export PYTEST_DISABLE_PLUGIN_AUTOLOAD=1 &&
        export ROS_WS_DIR='$ROS_WS_DIR' &&
        pytest tests/system/test_live_pipeline.py -v
    "
else
    echo
    echo "== Skipping stage 3-4 end-to-end system test (pass --gpu to include it) =="
fi

echo
if [[ ${#FAILED[@]} -eq 0 ]]; then
    echo "All test stages passed."
    exit 0
else
    echo "Failed stages:"
    printf '  - %s\n' "${FAILED[@]}"
    exit 1
fi

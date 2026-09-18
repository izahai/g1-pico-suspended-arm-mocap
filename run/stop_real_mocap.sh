#!/usr/bin/env bash
# Stop the background real mocap session and release ports/robot.
set -u

echo "Stopping sim2real processes..."

# 1. Kill laptop-side teleopit / run_sim2real processes
PIDS=$(pgrep -f "mini.*3/envs/teleopi[t]/bin/python" || pgrep -f "[s]cripts/run/run_sim2real.py" || true)

if [ -n "$PIDS" ]; then
  echo "Found processes: $PIDS"
  # Try graceful TERM first
  kill $PIDS 2>/dev/null || true
  sleep 1
  # Force kill any remaining
  for p in $PIDS; do
    if kill -0 "$p" 2>/dev/null; then
      kill -9 "$p" 2>/dev/null || true
    fi
  done
  echo "Laptop sim2real process stopped."
else
  echo "No active laptop sim2real process found."
fi

# 2. Also stop any onboard session on the Orin if reachable (best effort)
ssh -o BatchMode=yes -o ConnectTimeout=2 unitree@192.168.123.164 \
  'pkill -9 -f "miniforge3/envs/teleopi[t]/bin/python"' 2>/dev/null || true

echo "Done. Robot command stream released."
echo "Note: If the robot is still stiff, press L1+R1 on the Unitree remote for DAMPING."


#!/usr/bin/env bash
# One-command Teleopit session launcher (laptop side).
#   bash run/real_mocap.sh                 # background session
#   bash run/real_mocap.sh --interactive   # keep keyboard controls attached
# Cleans stale processes/ports and starts sim2real. Background mode waits for
# "robot control ready"; interactive mode runs until Teleopit exits.
# The PicoBridge headset app connects BY ITSELF ~5 s after robot control is ready
# (via the discovery relay on the Orin, see lab/orin/README.md).
#
# Env overrides:
#   TELEOPIT_IFACE=<ifname>   wired interface to the robot (default: auto-detect
#                             the interface that owns 192.168.123.x)
#   TELEOPIT_POLICY=<path>    ONNX policy (default ckpt/track_g1.onnx)
set -u
if [ "$#" -gt 1 ]; then
  echo "Usage: bash run/real_mocap.sh [--interactive]" >&2
  exit 2
fi
INTERACTIVE=0
case "${1:-}" in
  "") ;;
  --interactive|-i) INTERACTIVE=1 ;;
  *) echo "Usage: bash run/real_mocap.sh [--interactive]" >&2; exit 2 ;;
esac
if [ "$INTERACTIVE" -eq 1 ] && [ ! -t 0 ]; then
  echo "ABORT: --interactive requires a terminal for 1/2/3 keyboard control." >&2
  exit 1
fi
cd "$(dirname "$0")/.."
# The teleopit environment may be editable-installed from another checkout.
# Always load this launcher's code and config together.
export PYTHONPATH="$PWD${PYTHONPATH:+:$PYTHONPATH}"

PY=""
for c in "$HOME/miniforge3/envs/teleopit/bin/python" \
         "$HOME/miniconda3/envs/teleopit/bin/python" \
         "$(command -v python3 || true)" \
         "$(command -v python || true)"; do
  if [ -n "$c" ] && [ -x "$c" ]; then PY="$c"; break; fi
done
if [ -z "$PY" ]; then
  echo "ABORT: no Python interpreter found."
  exit 1
fi
POLICY="${TELEOPIT_POLICY:-ckpt/track_g1.onnx}"

# --- robot LAN interface ------------------------------------------------------
# The USB-GbE dongle name changes when the adapter changes (enx000ec6c3d44a,
# enx000ec6c10aa5, ...), and the built-in port (enp0s31f6) is also wired for
# robot-lan. Detect whichever interface currently carries 192.168.123.x.
IFACE="${TELEOPIT_IFACE:-}"
if [ -z "$IFACE" ]; then
  IFACE=$(ip -o -4 addr show | awk '$4 ~ /^192\.168\.123\./ {print $2; exit}')
fi
if [ -z "$IFACE" ]; then
  echo "ABORT: no interface has a 192.168.123.x address (robot LAN not up)."
  echo "  Plug the Ethernet cable, then: nmcli con up robot-lan   (or robot-lan-usb)"
  echo "  or set TELEOPIT_IFACE=<ifname> explicitly."
  exit 1
fi

# --- guard: never two commanders --------------------------------------------
# If an onboard session is running on the Orin, this laptop launcher must not
# start a second one: the robot obeys whichever stream persists and no remote
# button can win.
if ssh -o BatchMode=yes -o ConnectTimeout=4 unitree@192.168.123.164 \
     'pgrep -f "miniforge3/envs/teleopi[t]/bin/python" >/dev/null' 2>/dev/null; then
  echo "ABORT: an ONBOARD Teleopit session is running on the robot."
  echo "Kill it first:  ssh unitree@192.168.123.164 'pkill -9 -f miniforge3/envs/teleopit'"
  exit 1
fi

# --- free the receiver port ----------------------------------------------------
# old teleopit processes + the XRoboToolkit PC service (systemd USER unit that
# squats TCP 63901)
systemctl --user stop holosim-pcservice 2>/dev/null
for p in $(pgrep -f "mini.*3/envs/teleopi[t]/bin/python" || pgrep -f "[s]cripts/run/run_sim2real.py"); do kill -9 "$p" 2>/dev/null; done
sleep 2

LOG=/tmp/session_monitor/sim2real.log
mkdir -p /tmp/session_monitor
CMD=("$PY" -u scripts/run/run_sim2real.py \
    --config-name pico4_sim2real \
    controller.policy_path="$POLICY" \
    real_robot.network_interface="$IFACE")
if [ "$INTERACTIVE" -eq 1 ]; then
  echo "interface=$IFACE  policy=$POLICY  interactive terminal controls: 1=left arm, 2=right arm, 3=both arms, H=help"
  exec "${CMD[@]}"
fi
echo "interface=$IFACE  policy=$POLICY  log=$LOG"
setsid nohup "${CMD[@]}" > "$LOG" 2>&1 < /dev/null &

for i in $(seq 1 30); do
  sleep 1
  if grep -q "robot control ready" "$LOG" 2>/dev/null; then
    echo "READY - mode IDLE. Headset app connects itself in ~5 s."
    echo "Unitree remote: Start=STANDING  Y=MOCAP  X=STANDING  B=pause/resume  L1+R1=DAMP (robot goes limp - tether!)"
    echo "Pico controllers: A=pause/resume  B=ARMS mode  right-stick click=JOYSTICK walking"
    echo "Stop: bash lab/teleopit_estop.sh   (kills the command stream)"
    exit 0
  fi
  if grep -qE "Error|Traceback" "$LOG" 2>/dev/null; then
    echo "FAILED - last log lines:"; tail -5 "$LOG"; exit 1
  fi
done
echo "TIMEOUT waiting for ready - tail $LOG"; exit 1

#!/usr/bin/env bash
# Stream sim2real mocap logs in real-time
LOG="/tmp/session_monitor/sim2real.log"

if [ ! -f "$LOG" ]; then
  mkdir -p "$(dirname "$LOG")"
  touch "$LOG"
fi

exec tail -f "$LOG"


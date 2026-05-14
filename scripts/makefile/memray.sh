#!/bin/bash
# Memory profiling with interactive memray

# Ensure gdb is installed for attachment capabilities
dpkg -s gdb >/dev/null 2>&1 || (apt-get update && apt-get install -y gdb)

mkdir -p /tmp/memray
OUTPUT_BIN="/tmp/memray-live.bin"

# Locate the Gunicorn worker PID
MASTER_PID=$(ps -ef | grep gunicorn | grep -v grep | awk '{print $3, $2}' | sort -n | head -n1 | awk '{print $2}')
WORKER_PID=$(ps -ef | grep gunicorn | grep -v grep | awk -v master=$MASTER_PID '$3 == master {print $2}' | head -n1)

if [ -z "$WORKER_PID" ]; then
  echo "Error: No Gunicorn worker process found!"
  exit 1
fi

# 1. START TRACING
echo -e "\n🟢 Attaching to Worker PID: $WORKER_PID. Starting tracking..."
memray attach $WORKER_PID --output $OUTPUT_BIN --force

echo -e "\n👉 Memray is now active and recording memory allocations."
echo -e "👉 Send your HTTP traffic or requests to the server now."
echo -e "👉 Once tests complete, return here and press [ENTER] to stop."
read -r

# 2. DETACH PROCESS AND STOP RECORDING
echo -e "\n🔴 Detaching from process (memray detach)..."
memray detach $WORKER_PID

# 3. SHOW RESULTS
if [ -f "$OUTPUT_BIN" ]; then
  echo -e "\n=== ALLOCATION TREE (Peak Memory) ==="
  memray tree $OUTPUT_BIN
  
  echo -e "\nPress ENTER to display the full summary table..."
  read -r
  
  memray summary $OUTPUT_BIN
  rm -f $OUTPUT_BIN
else
  echo "Error: Binary output file not found."
fi
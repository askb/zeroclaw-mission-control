#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation
##############################################################################
# ZeroClaw Mission Control — Start with auto device pairing
# Usage: ./scripts/start.sh
##############################################################################

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_DIR="$PROJECT_DIR/docker"

cd "$COMPOSE_DIR"

echo "🦞 ZeroClaw Mission Control — Starting..."

# Step 1: Check .env exists
if [[ ! -f .env ]]; then
    echo "ERROR: docker/.env not found. Run scripts/setup.sh first." >&2
    exit 1
fi

# Step 2: Start gateway + redis
echo "  ⏳ Starting gateway and redis..."
docker compose up -d gateway redis

# Step 3: Wait for gateway healthy
echo "  ⏳ Waiting for gateway to become healthy..."
for i in $(seq 1 20); do
    STATUS=$(docker inspect zeroclaw-gateway --format='{{.State.Health.Status}}' 2>/dev/null || echo "missing")
    if [[ "$STATUS" == "healthy" ]]; then
        echo "  ✅ Gateway is healthy"
        break
    fi
    if [[ "$i" -eq 20 ]]; then
        echo "  ❌ Gateway failed to become healthy after 100s" >&2
        docker logs zeroclaw-gateway 2>&1 | tail -10
        exit 1
    fi
    sleep 5
done

# Step 4: Start Mission Control
echo "  ⏳ Starting Mission Control..."
docker compose up -d mission-control

# Step 5: Fix MC identity directory permissions
sleep 2
docker exec -u root mission-control chown -R node:node /home/node/.mission-control 2>/dev/null || true

# Step 6: Restart MC so it creates device identity with correct perms
echo "  ⏳ Restarting MC to generate device identity..."
docker compose restart mission-control
sleep 10

# Step 7: Check if MC needs device pairing and auto-approve
MC_LOG=$(docker logs --since 15s mission-control 2>&1)
if echo "$MC_LOG" | grep -q "pairing required"; then
    echo "  🔑 Approving MC device..."
    docker exec zeroclaw-gateway python3 << 'PYEOF'
import json, time, os
pending_path = "/home/node/.openclaw/devices/pending.json"
paired_path = "/home/node/.openclaw/devices/paired.json"
if not os.path.exists(pending_path):
    print("No pending devices"); exit(0)
with open(pending_path) as f:
    pending = json.load(f)
if not pending:
    print("No pending devices"); exit(0)
try:
    with open(paired_path) as f:
        paired = json.load(f)
except Exception:
    paired = {}
now_ms = int(time.time() * 1000)
all_scopes = [
    "operator.admin", "operator.read", "operator.write",
    "operator.approvals", "operator.pairing",
]
for req_id, dev in list(pending.items()):
    did = dev["deviceId"]
    paired[did] = {
        "deviceId": did,
        "publicKey": dev["publicKey"],
        "platform": dev["platform"],
        "clientId": dev["clientId"],
        "clientMode": dev["clientMode"],
        "role": "operator",
        "roles": ["operator"],
        "scopes": all_scopes,
        "approvedScopes": all_scopes,
        "createdAtMs": now_ms,
        "approvedAtMs": now_ms,
    }
    del pending[req_id]
with open(pending_path, "w") as f:
    json.dump(pending, f, indent=2)
with open(paired_path, "w") as f:
    json.dump(paired, f, indent=2)
print("Approved " + str(len(paired)) + " device(s)")
PYEOF

    # Restart MC to connect with approved identity
    echo "  ⏳ Reconnecting MC with approved device..."
    docker compose restart mission-control
    sleep 8
fi

# Step 8: Verify
echo ""
echo "  📊 Service Status:"
docker compose ps --format "table {{.Name}}\t{{.Status}}"
echo ""

MC_LOG=$(docker logs --since 10s mission-control 2>&1)
if echo "$MC_LOG" | grep -q "Authenticated successfully"; then
    if echo "$MC_LOG" | grep -q "missing scope"; then
        echo "  ⚠️  MC connected but missing operator scope — check pairing"
    else
        echo "  ✅ Mission Control connected with operator access!"
    fi
else
    echo "  ⚠️  MC may still be connecting — check: docker logs mission-control"
fi

LAN_IP=$(hostname -I | awk '{print $1}')
echo ""
echo "  🌐 Dashboard: http://${LAN_IP}:4000"
echo "  🔌 Gateway:   ws://${LAN_IP}:18789"
echo ""
echo "  🦞 ZeroClaw is ready!"

#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# Dumps gateway usage-cost data to a shared JSON file
set -euo pipefail
OUTPUT_DIR="/data/usage"
mkdir -p "$OUTPUT_DIR"
openclaw gateway usage-cost --json --days 30 > "$OUTPUT_DIR/usage-30d.json.tmp" 2>/dev/null
mv "$OUTPUT_DIR/usage-30d.json.tmp" "$OUTPUT_DIR/usage-30d.json"
echo "$(date -Iseconds) Usage data written to $OUTPUT_DIR/usage-30d.json"

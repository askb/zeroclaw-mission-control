#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 The Linux Foundation
# Dump GitHub + Gerrit review data for the dashboard
set -euo pipefail

REVIEWS_DIR="${HOME}/git/github/zeroclaw-mission-control/data/reviews"
REVIEWS_FILE="${REVIEWS_DIR}/reviews.json"
SECRETS_FILE="${HOME}/git/github/zeroclaw-mission-control/config/gateway/secrets.json"
UA="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) ZeroClaw-Dashboard/1.0"

mkdir -p "${REVIEWS_DIR}"

# Read tokens
GITHUB_TOKEN=$(python3 -c "import json; print(json.load(open('${SECRETS_FILE}'))['GITHUB_RO_TOKEN'])")
GERRIT_USER=$(python3 -c "import json; print(json.load(open('${SECRETS_FILE}'))['GERRIT_HTTP_USER'])")
GERRIT_PASS=$(python3 -c "import json; print(json.load(open('${SECRETS_FILE}'))['GERRIT_HTTP_PASS'])")

GERRIT="https://git.opendaylight.org/gerrit"
GITHUB="https://api.github.com"

gerrit_query() {
    local query="$1"
    curl -sf -H "User-Agent: ${UA}" "${GERRIT}/changes/?q=${query}&n=30" 2>/dev/null \
        | sed "s/^)]}'//g" || echo "[]"
}

github_query() {
    local endpoint="$1"
    curl -sf -H "Authorization: Bearer ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "${GITHUB}${endpoint}" 2>/dev/null || echo "{}"
}

echo "Fetching Gerrit data..."
MY_CHANGES=$(gerrit_query "status:open+owner:${GERRIT_USER}")
REVIEWER_CHANGES=$(gerrit_query "status:open+reviewer:${GERRIT_USER}")
MERGED_RECENT=$(gerrit_query "status:merged+-age:1d+(project:releng/builder+OR+project:releng/global-jjb)")

echo "Fetching GitHub data..."
INCOMING_PRS=$(github_query "/search/issues?q=is:pr+is:open+review-requested:askb+archived:false&per_page=30&sort=updated")
MY_PRS=$(github_query "/search/issues?q=is:pr+is:open+author:askb+archived:false&per_page=30&sort=updated")

# Assemble JSON
python3 -c "
import json, sys
from datetime import datetime

data = {
    'source': 'live',
    'timestamp': datetime.utcnow().isoformat() + 'Z',
    'gerrit': {
        'my_changes': json.loads('''${MY_CHANGES}'''),
        'pending_reviews': json.loads('''${REVIEWER_CHANGES}'''),
        'recently_merged': json.loads('''${MERGED_RECENT}''')
    },
    'github': {
        'incoming_prs': json.loads('''${INCOMING_PRS}'''),
        'my_prs': json.loads('''${MY_PRS}''')
    }
}
json.dump(data, sys.stdout, indent=2)
" > "${REVIEWS_FILE}"

echo "Reviews data written to ${REVIEWS_FILE}"

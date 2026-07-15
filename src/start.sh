#!/bin/bash
set -euo pipefail

# Required env vars:
: "${GITHUB_ORG:?GITHUB_ORG is required}"
: "${GITHUB_REPO:?GITHUB_REPO is required}"
: "${GITHUB_PAT:?GITHUB_PAT is required}"
: "${RUNNER_LABELS:?RUNNER_LABELS is required}"

# Exchange PAT for Runner Token
TOKEN_URL="https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners/registration-token"
REMOVE_URL="https://api.github.com/repos/${GITHUB_ORG}/${GITHUB_REPO}/actions/runners/remove-token"

echo "Requesting registration token..."
REG_TOKEN=$(curl -sS -X POST \
    -H "Authorization: Bearer ${GITHUB_PAT}" \
    -H "Accept: application/vnd.github+json" \
    "${TOKEN_URL}" | jq -r .token)

if [[ -z "$REG_TOKEN" || "$REG_TOKEN" == "null" ]]; then
    echo "Failed to get registration token"
    exit 1
fi

echo "Requesting removal token..."
REMOVE_TOKEN=$(curl -sS -X POST \
    -H "Authorization: Bearer ${GITHUB_PAT}" \
    -H "Accept: application/vnd.github+json" \
    "${REMOVE_URL}" | jq -r .token)
if [[ -z "$REMOVE_TOKEN" || "$REMOVE_TOKEN" == "null" ]]; then
    echo "Failed to get removal token"
    exit 1
fi

# Configure runner
SCOPE_URL="https://github.com/${GITHUB_ORG}/${GITHUB_REPO}"
./config.sh \
  --url "${SCOPE_URL}" \
  --token "${REG_TOKEN}" \
  --name "${RUNNER_NAME}" \
  --labels "${RUNNER_LABELS}" \
  --work _work \
  --unattended \
  --ephemeral \
  --disableupdate

# Register cleanup
cleanup() {
  echo "Removing runner..."
  ./config.sh remove --unattended --token "${REMOVE_TOKEN}"
}
trap cleanup EXIT

# Remove sensitive values
unset GITHUB_PAT REG_TOKEN

echo "starting runner.."
./run.sh

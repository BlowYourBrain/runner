#!/usr/bin/env bash
set -e

if [[ -z "$GITHUB_PAT" || -z "$GITHUB_REPOSITORY" ]]; then
  echo "❌ GITHUB_PAT or GITHUB_URL not set"
  exit 1
fi

OWNER=$(echo "$GITHUB_REPOSITORY" | cut -d/ -f1)
REPO=$(echo "$GITHUB_REPOSITORY" | cut -d/ -f2)

echo "🔑 Requesting runner registration token..."

REG_TOKEN=$(curl -s -X POST \
  -H "Authorization: token ${GITHUB_PAT}" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/${OWNER}/${REPO}/actions/runners/registration-token \
  | jq -r .token)

if [[ "$REG_TOKEN" == "null" || -z "$REG_TOKEN" ]]; then
  echo "❌ Failed to get registration token"
  exit 1
fi

cd /opt/runner

./config.sh \
  --url https://github.com/${GITHUB_REPOSITORY} \
  --token ${REG_TOKEN} \
  --unattended \
  --replace \
  --name android-docker-runner \
  --labels android,self-hosted

cleanup() {
  echo "🧹 Removing runner..."
  ./config.sh remove --token ${REG_TOKEN}
}
trap cleanup EXIT

./run.sh

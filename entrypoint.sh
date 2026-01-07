#!/bin/bash
set -e

cleanup() {
  echo "Removing runner..."
  ./config.sh remove --unattended --token "$GITHUB_TOKEN"
}
trap cleanup EXIT

./config.sh \
  --url "$GITHUB_URL" \
  --token "$GITHUB_TOKEN" \
  --name "android-docker-runner" \
  --labels "self-hosted,android,docker" \
  --unattended \
  --replace

./run.sh

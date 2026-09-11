#!/usr/bin/env bash

set -euo pipefail

# export NEMOCLAW_MODEL=${1:-nvidia/nemotron-3-super-120b-a12b}?
export NEMOCLAW_MODEL=${1:-nvidia/nemotron-3-ultra-550b-a55b}
echo Changing model to ${NEMOCLAW_MODEL} 

SANDBOX_NAME="${NEMOCLAW_SANDBOX_NAME:-my-deepagents}"
SKIP_GPU="${SKIP_GPU:-0}"

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$1"; }

# Pick up NVIDIA_INFERENCE_API_KEY (and anything else) from .env if present.
if [ -f .env ]; then
  log "Loading .env"
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

### Onboard #######################################################
log "Running nemoclaw onboarding # (resume in case GPU setup above was needed first)"
NEMOCLAW_NON_INTERACTIVE=1 \
  NEMOCLAW_AGENT=langchain-deepagents-code \
  NEMOCLAW_PROVIDER=build \
  NEMOCLAW_MODEL=${NEMOCLAW_MODEL:-nvidia/nemotron-3-super-120b-a12b} \
  NEMOCLAW_ACCEPT_THIRD_PARTY_SOFTWARE=1 \
  NEMOCLAW_POLICY_TIER=restricted \
  nemoclaw onboard --yes --name $SANDBOX_NAME

### Rebuild the sandbox ####################################################
log "Rebuilding sandbox: $SANDBOX_NAME"
NEMOCLAW_NON_INTERACTIVE=1 \
  NEMOCLAW_AGENT=langchain-deepagents-code \
  NEMOCLAW_PROVIDER=nvidia-prod \
  NEMOCLAW_MODEL="${NEMOCLAW_MODEL:-nvidia/nemotron-3-super-120b-a12b}" \
  NEMOCLAW_ACCEPT_THIRD_PARTY_SOFTWARE=1 \
  NEMOCLAW_POLICY_TIER=restricted \
  nemoclaw "$SANDBOX_NAME" rebuild --dcode-auto-approval thread-opt-in --yes
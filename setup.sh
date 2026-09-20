#!/usr/bin/env bash
# Bootstraps nemoclaw + deepagents on a fresh host, following the steps
# documented in README.md (host requirements, GPU passthrough, sandbox rebuild)
# plus NVIDIA's deepagents quickstart installer:
# https://docs.nvidia.com/nemoclaw/latest/user-guide/deepagents/get-started/quickstart
set -euo pipefail

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

### 1. Host requirements (mount sharing) #####################################
log "Installing host requirements: sshfs, bindfs"
sudo apt-get update
sudo apt-get install -y sshfs bindfs

log "Enabling user_allow_other in /etc/fuse.conf"
sudo sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf

### 2. GPU passthrough (NVIDIA container toolkit + CDI) ######################
if [ "$SKIP_GPU" = "1" ]; then
  log "SKIP_GPU=1 set, skipping GPU passthrough setup"
elif ! command -v nvidia-smi >/dev/null 2>&1; then
  log "No nvidia-smi found, skipping GPU passthrough setup (set SKIP_GPU=0 and install NVIDIA drivers to enable)"
else
  log "Installing NVIDIA container toolkit"
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
  curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
  sudo apt-get update
  sudo apt-get install -y nvidia-container-toolkit

  log "Generating CDI spec for WSL2/container GPU access"
  sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

  log "Verifying GPU visibility to containers"
  nvidia-ctk cdi list
fi

### 3. Install nemoclaw + deepagents ##########################################
if command -v nemoclaw >/dev/null 2>&1; then
  log "nemoclaw already installed, skipping installer"
else
  log "Installing nemoclaw with the deepagents agent (sandbox: $SANDBOX_NAME)"
  curl -fsSL https://www.nvidia.com/nemoclaw.sh | \
    NEMOCLAW_AGENT=langchain-deepagents-code \
    NEMOCLAW_SANDBOX_NAME="$SANDBOX_NAME" \
    NEMOCLAW_PROVIDER=build \
    NEMOCLAW_FRESH=1 \
    NEMOCLAW_NO_EXPRESS=1  \
    NEMOCLAW_ACCEPT_THIRD_PARTY_SOFTWARE=1 \
    bash -s -- --non-interactive
fi

### 4. Onboard #######################################################
log "Running nemoclaw onboarding # (resume in case GPU setup above was needed first)"
NEMOCLAW_NON_INTERACTIVE=1 \
  NEMOCLAW_AGENT=langchain-deepagents-code \
  NEMOCLAW_PROVIDER=build \
  NEMOCLAW_MODEL=nvidia/nemotron-3-super-120b-a12b \
  NEMOCLAW_ACCEPT_THIRD_PARTY_SOFTWARE=1 \
  NEMOCLAW_POLICY_TIER=restricted \
  nemoclaw onboard --yes --name $SANDBOX_NAME

### 5. Rebuild the sandbox ####################################################
log "Rebuilding sandbox: $SANDBOX_NAME"
NEMOCLAW_NON_INTERACTIVE=1 \
  NEMOCLAW_AGENT=langchain-deepagents-code \
  NEMOCLAW_PROVIDER=nvidia-prod \
  NEMOCLAW_MODEL=nvidia/nemotron-3-super-120b-a12b \
  NEMOCLAW_ACCEPT_THIRD_PARTY_SOFTWARE=1 \
  NEMOCLAW_POLICY_TIER=restricted \
  nemoclaw "$SANDBOX_NAME" rebuild --dcode-auto-approval thread-opt-in --yes

### 6. Verify + launch ########################################################
log "Checking sandbox status"
nemoclaw "$SANDBOX_NAME" status

log "Setup complete. Launch with:"
echo "  nemo-deepagents launch $SANDBOX_NAME"
echo "Or connect with:"
echo nemoclaw "$SANDBOX_NAME" connect

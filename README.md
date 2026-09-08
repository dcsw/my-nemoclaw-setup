# my-nemoclaw-setup
A nemoclaw setup for reproduceability and cached speed-setup.

## How I made this
From a [near] empty repo, run claude and paste in NVIDIA's prompt from https://docs.nvidia.com/nemoclaw/latest/user-guide/deepagents/get-started/quickstart.

### Install host requirements

- For sandbox mount sharing:
```
sudo apt-get install -y sshfs
```

- Setup mount sharing
```
sudo sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf
sudo apt-get install -y bindfs
```


### Mount a sandbox path on the host

To edit or test sandbox files (e.g. loading a browser extension "unpacked" in Brave/Chrome) with a live view backed by the sandbox filesystem:
```
mkdir -p ~/mnt/<mount-name>
nemoclaw <sandbox-name> share mount <sandbox-path> ~/mnt/<mount-name>
```
Changes made inside the sandbox appear at the mount point instantly, and vice versa.


# Then I also....

## Added GPU passthrough

```
# 1. Add the NVIDIA repository and install the toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# 2. Generate the CDI specifications (Critical for WSL2)
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

# 3. Verify the GPU is visible to containers
nvidia-ctk cdi list
# You should see 'nvidia.com/gpu' entries listed.

# Extra. Resume the onboarding if/as necessary when doing these steps manually....
nemoclaw onboard --resume   
```

### To rebuild the sandbox:
```
NEMOCLAW_NON_INTERACTIVE=1 NEMOCLAW_PROVIDER=nvidia-prod NEMOCLAW_MODEL=nvidia/nemotron-3-super-120b-a12b NEMOCLAW_ACCEPT_THIRD_PARTY_SOFTWARE=1 NEMOCLAW_POLICY_TIER=restricted nemoclaw appointment-minder rebuild --dcode-auto-approval thread-opt-in --yes
```

## Share the folder
```
nemoclaw share mount tmp /sandbox/example
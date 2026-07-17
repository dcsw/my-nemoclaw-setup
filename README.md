# my-nemoclaw-setup
A nemoclaw setup for reproduceability and cached speed-setup.

## How I made this
From a [near] empty repo, run claude and paste in NVIDIA's prompt from https://docs.nvidia.com/nemoclaw/latest/user-guide/deepagents/get-started/quickstart.

### Install host requirements

- For sandbox mount sharing:
```
sudo apt-get install -y sshfs
```

### Mount a sandbox path on the host

To edit or test sandbox files (e.g. loading a browser extension "unpacked" in Brave/Chrome) with a live view backed by the sandbox filesystem:
```
mkdir -p ~/mnt/<mount-name>
nemoclaw <sandbox-name> share mount <sandbox-path> ~/mnt/<mount-name>
```
Changes made inside the sandbox appear at the mount point instantly, and vice versa.
# Synchronization Commands

## Rsync to Remote Laptop (`cer@10.0.32.45`)

Target Directory on Server: `~/nthai/g1-pico-suspended-arm-mocap`  
*(A symlink `~/nthai/g1-pico-suspened-arm-mocap` also points to this directory).*

### 1. Execute Rsync (Recommended Multi-line)

Run this from the repository root (`/Users/hainguyen/Repo/VNG/g1_teleoperate/g1-pico-suspended-arm-mocap`):

```bash
rsync -avh --progress \
  --exclude='.git/' \
  --exclude='*.apk' \
  --exclude='*.onnx' \
  --exclude='*.pt' \
  --exclude='*.pth' \
  --exclude='*.h5' \
  --exclude='__pycache__/' \
  --exclude='*.pyc' \
  --exclude='.pytest_cache/' \
  --exclude='.venv/' \
  --exclude='venv/' \
  --exclude='*.mp4' \
  --exclude='*.gif' \
  --exclude='*.log' \
  --exclude='build/' \
  --exclude='dist/' \
  --exclude='*.egg-info/' \
  --exclude='.DS_Store' \
  ./ cer@10.0.32.45:/home/cer/nthai/g1-pico-suspended-arm-mocap/
```

### 2. Single-line Command

```bash
rsync -avh --progress --exclude='.git/' --exclude='*.apk' --exclude='*.onnx' --exclude='*.pt' --exclude='*.pth' --exclude='*.h5' --exclude='__pycache__/' --exclude='*.pyc' --exclude='.pytest_cache/' --exclude='.venv/' --exclude='venv/' --exclude='*.mp4' --exclude='*.gif' --exclude='*.log' --exclude='build/' --exclude='dist/' --exclude='*.egg-info/' --exclude='.DS_Store' ./ cer@10.0.32.45:/home/cer/nthai/g1-pico-suspended-arm-mocap/
```

### 3. Dry-Run (Preview changes without transferring)

```bash
rsync -avh --dry-run --stats \
  --exclude='.git/' \
  --exclude='*.apk' \
  --exclude='*.onnx' \
  --exclude='*.pt' \
  --exclude='*.pth' \
  --exclude='*.h5' \
  --exclude='__pycache__/' \
  --exclude='*.pyc' \
  --exclude='.pytest_cache/' \
  --exclude='.venv/' \
  --exclude='venv/' \
  --exclude='*.mp4' \
  --exclude='*.gif' \
  --exclude='*.log' \
  --exclude='build/' \
  --exclude='dist/' \
  --exclude='*.egg-info/' \
  --exclude='.DS_Store' \
  ./ cer@10.0.32.45:/home/cer/nthai/g1-pico-suspended-arm-mocap/
```

---

## SSH Remote Access

SSH public key (`~/.ssh/id_ed25519.pub`) has been authorized on the server for passwordless login:

```bash
ssh cer@10.0.32.45
```


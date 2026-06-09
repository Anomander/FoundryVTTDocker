# Foundry VTT – Self-Hosted Docker (Unraid + GitHub Actions)

A minimal, self-contained Docker setup for running [Foundry Virtual Tabletop](https://foundryvtt.com) on Unraid.

- **No third-party Foundry images.** You download the official release zip from Foundry and publish it as a GitHub Release. GitHub Actions builds and publishes the Docker image automatically.
- **Version-pinned.** Every published release gets a permanent tag on ghcr.io. Upgrading and rolling back are explicit.
- **No credentials in CI.** The build uses the automatic `GITHUB_TOKEN` — no secrets to configure.
- **Unraid-native.** Managed through the Unraid Docker UI. No Compose required.
- **No large files in git.** The Foundry zip (~250MB) is attached to a GitHub Release, not committed to the repo.

---

## How It Works

```
1. Download zip from foundryvtt.com
2. Run: ./scripts/update-release.sh 13.352 ~/Downloads/FoundryVTT-13.352.zip
         └─ creates a GitHub Release tagged v13.352
         └─ uploads the zip as a release asset (never touches git)
3. GitHub Actions triggers on release publication
         └─ downloads the zip from the release
         └─ builds Docker image
         └─ pushes ghcr.io/<you>/foundryvtt:13.352 and :latest
4. Unraid: edit container → update Repository tag → Apply
         └─ pulls new image from ghcr.io, restarts container
```

---

## Repository Layout

```
FoundryVTTDocker/
├── Dockerfile            # builds the image from release/foundryvtt.zip
├── foundryvtt.xml        # Unraid Docker template
├── .env.example          # runtime config template (admin key only)
├── .gitignore
├── release/
│   └── README.md         # explains that zips go to GitHub Releases
├── .github/
│   └── workflows/
│       └── build-and-push.yml   # CI: triggered by GitHub Release
├── scripts/
│   ├── update-release.sh # PRIMARY: publish a release to trigger CI
│   ├── build.sh          # optional: build locally without pushing
│   └── backup.sh         # run on Unraid to snapshot data
└── backups/              # timestamped backups (gitignored)
```

---

## Prerequisites

| Requirement | Notes |
|---|---|
| **gh CLI** | `brew install gh` then `gh auth login` (for `update-release.sh`) |
| **GitHub account** | The repo must be on GitHub for Actions + ghcr.io to work |
| **Foundry VTT license** | Required to download releases from foundryvtt.com |
| **Unraid with Docker** | Your server |

---

## One-Time Setup

### 1 – Install the GitHub CLI

```bash
brew install gh
gh auth login    # follow the prompts to authenticate
```

### 2 – Clone the repo

```bash
git clone git@github.com:YOUR_USERNAME/FoundryVTTDocker.git
cd FoundryVTTDocker
```

### 3 – Make the ghcr.io package public

After the first CI run, GitHub creates the `foundryvtt` package in your account. By default it is private. Make it public so Unraid can pull without credentials:

1. Go to `https://github.com/YOUR_USERNAME?tab=packages`
2. Click **foundryvtt**
3. **Package settings** → **Change visibility** → **Public**

> You only need to do this once.

### 4 – Publish the first release

Download the Foundry Linux/Node.js zip for your desired version from [foundryvtt.com → Purchased Licenses → Downloads](https://foundryvtt.com), then run:

```bash
./scripts/update-release.sh 13.351 ~/Downloads/FoundryVTT-13.351.zip
```

This creates a GitHub Release tagged `v13.351` and uploads the zip as an asset.
The zip never enters git history.

### 5 – Wait for CI to finish

Go to `https://github.com/YOUR_USERNAME/FoundryVTTDocker/actions` and watch the build. When it goes green, the image is available at:

```
ghcr.io/YOUR_USERNAME/foundryvtt:13.351
```

The exact tag is also printed in the **job summary** on the Actions run page.

### 6 – Install the Unraid template

SSH into your Unraid server:

```bash
cp foundryvtt.xml /boot/config/plugins/dockerMan/templates-user/foundryvtt.xml
```

Or use the Unraid web file manager to upload it.

### 7 – Add the container in Unraid

1. Unraid UI → **Docker** tab → **Add Container**
2. Select **foundryvtt** from the template dropdown
3. Configure:

| Field | Value |
|---|---|
| **Repository** | `ghcr.io/YOUR_USERNAME/foundryvtt:13.351` |
| **Web Port** | `30000` (change host-side only if needed) |
| **Data Path** | `/mnt/user/appdata/foundryvtt` |
| **Admin Key** | a strong password |

4. Click **Apply**

Unraid pulls the image and starts the container.

### 8 – Verify

- Click the container icon in Unraid — Foundry setup page should open
- Complete the setup wizard (license key + admin key)
- Confirm your reverse proxy can reach `<unraid-ip>:30000`

---

## Upgrading

```bash
# 1. Download the new zip from foundryvtt.com

# 2. Run:
./scripts/update-release.sh 13.352 ~/Downloads/FoundryVTT-13.352.zip
#    → creates GitHub Release v13.352 with zip attached
#    → GitHub Actions builds and publishes the image automatically

# 3. Watch CI at: https://github.com/YOUR_USERNAME/FoundryVTTDocker/actions

# 4. In Unraid: Docker tab → foundryvtt → Edit
#    Update Repository to: ghcr.io/YOUR_USERNAME/foundryvtt:13.352
#    Click Apply → Unraid pulls and restarts
```

---

## Rolling Back

Every pushed version tag is permanent on ghcr.io. To roll back:

1. In Unraid: edit the container → set **Repository** to the old tag (e.g. `ghcr.io/YOUR_USERNAME/foundryvtt:13.351`)
2. Click **Apply**

No rebuild or re-push needed. List available versions at:
```
https://github.com/YOUR_USERNAME?tab=packages → foundryvtt → versions
```

---

## Backup & Restore

### Backup (on Unraid via SSH)

```bash
# From this repo's location on the Unraid server:
./scripts/backup.sh
```

Or manually:

```bash
docker stop foundryvtt
tar czf ~/foundry-backup-$(date +%Y%m%d).tar.gz /mnt/user/appdata/foundryvtt
docker start foundryvtt
```

Archives are saved to `backups/` (gitignored).

### Restore

```bash
docker stop foundryvtt
rm -rf /mnt/user/appdata/foundryvtt
mkdir -p /mnt/user/appdata/foundryvtt
tar xzf backups/foundry-data-TIMESTAMP.tar.gz -C /mnt/user/appdata/foundryvtt
docker start foundryvtt
```

---

## Troubleshooting

### CI build fails: "no zip asset found in release"

The release was created without a zip file attached, or the filename doesn't match `*.zip`. Re-run:

```bash
# Delete the failed release first
gh release delete v13.351 --yes

# Then recreate with the zip
./scripts/update-release.sh 13.351 ~/Downloads/FoundryVTT-13.351.zip
```

### Image won't pull on Unraid (401 / 403)

The ghcr.io package is still private. See **One-Time Setup → Step 3** to make it public.

### Container won't start

```bash
docker logs foundryvtt   # on Unraid via SSH
```

Common causes:
- Data path permissions — fix with: `chown -R 1000:1000 /mnt/user/appdata/foundryvtt`
- Wrong image tag in the Unraid template

### Check which version is running

```bash
docker inspect foundryvtt | grep -i image
```

---

## Reference

| Script | Run on | Purpose |
|---|---|---|
| `scripts/update-release.sh <ver> <zip>` | Your machine | Create GitHub Release with zip → triggers CI |
| `scripts/build.sh` | Your machine | Build locally for testing (no push) |
| `scripts/backup.sh` | Unraid (SSH) | Snapshot `/mnt/user/appdata/foundryvtt` |

| Container path | Purpose |
|---|---|
| `/data` | All user data — map to `/mnt/user/appdata/foundryvtt` |
| `/foundry` | Application files — do not mount |

| Port | Purpose |
|---|---|
| `30000` | Foundry web UI — point your reverse proxy here |

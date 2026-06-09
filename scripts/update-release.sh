#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# update-release.sh – Publish a new Foundry release to trigger the CI build
#
# Creates a GitHub Release tagged v<version> with the Foundry zip attached.
# GitHub Actions will automatically pick it up, build the Docker image,
# and push it to ghcr.io.
#
# The zip is uploaded directly to the GitHub Release — it never touches
# git history.
#
# Usage:
#   ./scripts/update-release.sh <version> <path-to-zip>
#
# Example:
#   ./scripts/update-release.sh 13.352 ~/Downloads/FoundryVTT-13.352.zip
#
# Prerequisites:
#   - gh CLI installed:  brew install gh
#   - Authenticated:     gh auth login
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Validate arguments ─────────────────────────────────────────────────────
VERSION="${1:-}"
ZIP_SOURCE="${2:-}"

if [[ -z "${VERSION}" || -z "${ZIP_SOURCE}" ]]; then
  echo "Usage: update-release.sh <version> <path-to-zip>"
  echo ""
  echo "Example:"
  echo "  ./scripts/update-release.sh 13.352 ~/Downloads/FoundryVTT-13.352.zip"
  exit 1
fi

# ── Expand ~ in path ───────────────────────────────────────────────────────
ZIP_SOURCE="${ZIP_SOURCE/#\~/$HOME}"

if [[ ! -f "${ZIP_SOURCE}" ]]; then
  echo "ERROR: Zip file not found: ${ZIP_SOURCE}"
  echo ""
  echo "  1. Log in to https://foundryvtt.com"
  echo "  2. Purchased Licenses → Downloads"
  echo "  3. Select version ${VERSION}, download Linux/Node.js zip"
  exit 1
fi

# ── Check gh CLI is installed and authenticated ────────────────────────────
if ! command -v gh &>/dev/null; then
  echo "ERROR: GitHub CLI (gh) is not installed."
  echo "  Install: brew install gh"
  echo "  Auth:    gh auth login"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo "ERROR: Not authenticated with GitHub CLI."
  echo "  Run: gh auth login"
  exit 1
fi

# ── Check tag doesn't already exist ───────────────────────────────────────
TAG="v${VERSION}"
if gh release view "${TAG}" --repo "${ROOT_DIR}" &>/dev/null 2>&1; then
  echo "ERROR: Release ${TAG} already exists."
  echo "  To overwrite: gh release delete ${TAG} --yes --repo <repo>"
  exit 1
fi

# ── Create the release and upload the zip ─────────────────────────────────
ZIP_SIZE="$(du -sh "${ZIP_SOURCE}" | cut -f1)"
echo "=== Publishing Foundry VTT ${VERSION} ==="
echo "  Tag     : ${TAG}"
echo "  Zip     : ${ZIP_SOURCE} (${ZIP_SIZE})"
echo ""
echo "Uploading to GitHub Release (this may take a minute)..."

gh release create "${TAG}" "${ZIP_SOURCE}" \
  --repo "${ROOT_DIR}" \
  --title "Foundry VTT ${VERSION}" \
  --notes "Foundry VTT ${VERSION} release artifact.

The attached zip is the official Linux/Node.js distribution from foundryvtt.com.
GitHub Actions will build and publish the Docker image automatically.

**Docker image:** \`ghcr.io/$(gh api user --jq .login)/foundryvtt:${VERSION}\`"

echo ""
echo "✓ Release published: ${TAG}"
echo ""

# ── Print follow-up info ───────────────────────────────────────────────────
REPO_URL="$(gh repo view --json url --jq .url 2>/dev/null || echo 'https://github.com/YOUR_USERNAME/FoundryVTTDocker')"
OWNER="$(gh api user --jq .login 2>/dev/null || echo 'YOUR_USERNAME')"

echo "GitHub Actions is now building the Docker image."
echo "Monitor progress at:"
echo "  ${REPO_URL}/actions"
echo ""
echo "Once complete, set this in your Unraid container template:"
echo "  ghcr.io/${OWNER}/foundryvtt:${VERSION}"

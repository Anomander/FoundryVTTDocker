#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# build.sh – Build the Foundry VTT Docker image LOCALLY (optional / fallback)
#
# The normal workflow is:
#   ./scripts/update-release.sh <version> <path-to-zip>
#   → commits + pushes → GitHub Actions builds and pushes to ghcr.io
#
# Use this script only if you want to build and test the image locally
# without pushing to the registry.
#
# Usage:
#   ./scripts/build.sh
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
RELEASE_DIR="${ROOT_DIR}/release"

# ── Read version from release/version ─────────────────────────────────────
VERSION_FILE="${RELEASE_DIR}/version"
if [[ ! -f "${VERSION_FILE}" ]]; then
  echo "ERROR: ${VERSION_FILE} not found."
  echo "       Run ./scripts/update-release.sh first to stage a release."
  exit 1
fi
VERSION="$(cat "${VERSION_FILE}" | tr -d '[:space:]')"

# ── Check the zip is present ───────────────────────────────────────────────
ZIP="${RELEASE_DIR}/foundryvtt.zip"
if [[ ! -f "${ZIP}" ]]; then
  echo "ERROR: ${ZIP} not found."
  echo ""
  echo "  1. Download the Linux/Node.js zip for version ${VERSION} from foundryvtt.com"
  echo "  2. Run:  ./scripts/update-release.sh ${VERSION} <path-to-zip>"
  echo ""
  exit 1
fi

# ── Build locally ──────────────────────────────────────────────────────────
IMAGE_TAG="foundryvtt:${VERSION}"
echo "Building local image: ${IMAGE_TAG}"
echo "  Version : ${VERSION}"
echo "  Zip     : ${ZIP} ($(du -sh "${ZIP}" | cut -f1))"
echo ""

docker build \
  --build-arg FOUNDRY_VERSION="${VERSION}" \
  --tag "${IMAGE_TAG}" \
  "${ROOT_DIR}"

echo ""
echo "✓ Local build complete: ${IMAGE_TAG}"
echo ""
echo "To test it:"
echo "  docker run --rm -p 30000:30000 -v foundry_data:/data ${IMAGE_TAG}"

#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# backup.sh – Snapshot the Foundry VTT data volume
#
# Usage:
#   ./scripts/backup.sh
#
# Creates a timestamped archive in backups/ containing all Foundry user data
# (worlds, systems, modules, configs). Safe to run while the container is
# running – it briefly pauses writes using docker stop/start if needed.
# ---------------------------------------------------------------------------
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONTAINER_NAME="foundryvtt"
VOLUME_NAME="foundryvtt_data"
BACKUP_DIR="${ROOT_DIR}/backups"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
ARCHIVE="${BACKUP_DIR}/foundry-data-${TIMESTAMP}.tar.gz"

mkdir -p "${BACKUP_DIR}"

echo "Backing up Foundry data volume → ${ARCHIVE}"

# Stop the container gracefully so data is in a consistent state
CONTAINER_WAS_RUNNING=false
if docker inspect "${CONTAINER_NAME}" &>/dev/null \
   && [[ "$(docker inspect -f '{{.State.Running}}' "${CONTAINER_NAME}")" == "true" ]]; then
  echo "  Stopping container '${CONTAINER_NAME}'..."
  docker stop "${CONTAINER_NAME}"
  CONTAINER_WAS_RUNNING=true
fi

# Run a throwaway Alpine container to tar the volume contents
docker run --rm \
  -v "${VOLUME_NAME}:/data:ro" \
  -v "${BACKUP_DIR}:/backups" \
  alpine \
  tar czf "/backups/foundry-data-${TIMESTAMP}.tar.gz" -C /data .

# Restart if it was running before
if [[ "${CONTAINER_WAS_RUNNING}" == "true" ]]; then
  echo "  Restarting container '${CONTAINER_NAME}'..."
  docker start "${CONTAINER_NAME}"
fi

echo "✓ Backup saved: ${ARCHIVE}"

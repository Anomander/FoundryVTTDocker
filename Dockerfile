# syntax=docker/dockerfile:1
# ---------------------------------------------------------------------------
# Foundry VTT – Custom Image
# ---------------------------------------------------------------------------
# Build argument: the Foundry version to package into this image.
# Read automatically from release/version by GitHub Actions.
#
# To build locally (optional):
#   docker build --build-arg FOUNDRY_VERSION=$(cat release/version) \
#     -t foundryvtt:$(cat release/version) .
# ---------------------------------------------------------------------------

# Foundry V12+ requires Node 20. Use node:18-slim for V11 or older.
ARG NODE_VERSION=20
FROM node:${NODE_VERSION}-slim

# Re-declare after FROM so it is in scope during build
ARG FOUNDRY_VERSION
ENV FOUNDRY_VERSION=${FOUNDRY_VERSION}

# Install only what is needed to run Foundry (unzip used at build time only)
RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /foundry

# The zip is downloaded from the GitHub Release by CI and placed here.
# See README.md for the full workflow.
COPY release/foundryvtt.zip ./foundryvtt.zip
RUN unzip -q foundryvtt.zip \
    && rm foundryvtt.zip

# The official node:*-slim image already ships with a 'node' user at UID 1000.
# Reuse it rather than creating a second user at the same UID.
RUN mkdir -p /data \
    && chown -R node:node /foundry /data

USER node

# /data holds worlds, systems, modules, and config – mount a volume here.
VOLUME /data

EXPOSE 30000

# --noupnp   : disable UPnP (we are behind a reverse proxy)
# --noupdate : disable Foundry's built-in update mechanism (we manage versions)
ENTRYPOINT ["node", "resources/app/main.js", \
    "--dataPath=/data", \
    "--port=30000", \
    "--noupnp", \
    "--noupdate"]

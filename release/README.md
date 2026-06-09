# release/

This directory exists as a build context mountpoint for the Dockerfile.

During a CI build, GitHub Actions downloads `foundryvtt.zip` from the
corresponding GitHub Release asset and places it here before running
`docker build`. The zip is **never committed to git**.

## How to publish a new version

Use the provided script, which creates a GitHub Release with the zip attached:

```bash
./scripts/update-release.sh 13.352 ~/Downloads/FoundryVTT-13.352.zip
```

See the project README for the full workflow.

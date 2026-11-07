# Deployment and release

No public deployment, repository or artifact publication is authorized. Local package only. No production service is running. Build script assembles an ad-hoc signed development bundle and records the Git commit. Before external distribution, complete signing, notarization, artifact checksums, version matching and platform QA.

Branches: testing development, beta prerelease preparation, main stable. Manual macOS GitHub Actions validation is configured; no GitHub repository exists yet and no remote run is claimed. iOS jobs are not configured until actual app/extension targets exist. Android APK/AAB jobs do not apply to the requested native Apple platforms.

Public update channels, update discovery and structured release artifact manifests remain future work. Never present sources-v1.0 metadata as an app version. No hardcoded private GitHub token is permitted.

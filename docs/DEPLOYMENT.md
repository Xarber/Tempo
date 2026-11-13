# Deployment and release

No public deployment, repository or artifact publication is authorized. Local package only. No production service is running. Build script assembles an ad-hoc signed development bundle and records the Git commit. Before external distribution, complete signing, notarization, artifact checksums, version matching and platform QA.

Branches: testing development, beta prerelease preparation, main stable. Manual macOS GitHub Actions validation is configured; no GitHub repository exists yet and no remote run is claimed. iOS jobs are not configured until actual app/extension targets exist. Android APK/AAB jobs do not apply to the requested native Apple platforms.

Public update channels, update discovery and structured release artifact manifests remain future work. Never present sources-v1.0 metadata as an app version. No hardcoded private GitHub token is permitted.

## X-Center web

Public endpoint is https://tempo.xcenter.it. Export from a clean checkout using
`EXPO_PUBLIC_TEMPO_DEPLOYMENT=xcenter npm run build:web`. This build-time
variable removes the QA mode and Developer Ideas unlock from the hosted UI.
It contains no secrets. The browser uses IndexedDB and requires no dedicated
API, database, sync server, or configurable server address.

Stage the export as a new directory under
`/srv/xcenter/apps/tempo/releases/<commit>`. Deploy the Nginx site from
`infra/x-center/tempo.conf` into the appliance's included
`/etc/nginx/sites-available/xcenter.d/` directory. Verify TLS compatibility and
`nginx -t`, then reload Nginx for initial provisioning. For subsequent updates
atomically switch the `/srv/xcenter/apps/tempo/current` symlink, retaining
the old target. Verify `/version.json` (uncached), `/`, `/focus`,
`/manifest.webmanifest` and `/sw.js` over public HTTPS. Switch the symlink
back to the previous release if validation fails. To withdraw a first
installation, remove only its site configuration, test and reload Nginx.

## Native build artifacts

GitHub Actions validates and packages macOS, plus parallel iOS device,
iOS simulator, Android universal APK and AAB builds on beta/main. The iOS
device and Android artifacts are unsigned and need a trusted signing identity.
The macOS package is ad hoc signed. The workflows upload artifacts with version,
channel and commit metadata. Store submissions and distribution signing have
separate setup requirements.

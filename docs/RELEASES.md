# Build and release

Integrate into testing and promote only after applicable checks pass. Beta and
main trigger the native artifact matrix. Validate target architectures, bundle
identity, checksums and source commit before considering publication.
The current channels are X-Center web and GitHub Actions build artifacts.
See DEPLOYMENT.md for the appliance and rollback procedure.

Track each future authorized release from built through validated, published and
verified. Record run links, checksums, screenshot review and distribution checks.
For a partial publication, retain valid assets and retry only the failed stage.
Automated release publication and native update feeds are pending.

# X-Center operations

Probe /version.json, /focus and /sw.js over HTTPS and compare the served commit
with the active release. Repeated probe failures or certificate expiry within
14 days warrant investigation by the deployment maintainer. Scheduled Tempo
alerts are pending. Incident and recovery procedures follow below.

Treat sustained failure of the core app as SEV1 and loss of installation or
offline assets as SEV2. Record observed times, commit and affected routes.
Inspect Nginx errors, restore the prior release link if needed and recheck HTTPS.
The deployed artifact is reproducible from Git. There is no server-side user
database to restore. Preserve versioned releases on the appliance and use
Tempo exports for user records. Recovery target is one hour for a recoverable
static deployment fault. Server-side user-data RPO is inapplicable.

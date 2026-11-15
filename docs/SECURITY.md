# Security boundaries

Tempo keeps session and project data on the device. The public X-Center host
serves static assets over HTTPS. Browser storage and native SQLite are separate.
A local device or browser profile with access to Tempo data can read its records.
Treat exported archives as sensitive. The application validates imports before
merging, and simulated web data uses a separate namespace.

Developer Options is a discoverability mechanism. It grants no backend
authorization. Report suspected flaws following the root SECURITY.md process.
Assess impact on existing records and downloads before publishing a fix.

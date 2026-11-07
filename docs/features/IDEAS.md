# Developer Ideas

Private ideas are stored in the same transactional local Archive, separate from ordinary tasks. Each has UUID, title, detail, category, priority, status, timestamps and optional implementation reference. Settings version triple tap unlocks developer controls for 30 seconds of inactivity; leaving the developer section for a main tab closes access. Editing refreshes the timeout.

Create/edit/delete, search, status filter, newest-first sorting, duplicate, copy and full JSON export/reviewed import are implemented. Existing IDs win on import; incoming changes to existing IDs are intentionally preserved separately rather than overwritten. Revision history, multi-select, dedicated idea-only export format, screenshots and explicit changelog navigation are not implemented.

docs/IDEAS.json starts empty. It is repository-visible input, not a mirror of private device storage. Agents must read it before substantial development, summarize actionable ideas and ask now/later for relevant unrelated work. No automatic implementation or synchronization is authorized. Export from the app deliberately before importing private records into this repository. Never include user ideas in public artifacts without approval.

# Tempo Web and mobile

The root route renders the product introduction. Entering explicitly remembers the preference locally. On later visits the workspace opens directly. The logo opens the introduction with `/?about=1`. The workspace remains mounted when navigating between these two views, so drafts, the selected section, and the timer remain available. `/focus` is a direct entry point. Native mobile starts on its React Native focus screen.

Run `npm ci` and `npm run build:web`. Run `node scripts/serve-web.mjs` and open `http://127.0.0.1:4173/` for local production preview. X-Center is the planned hosting target. Its HTTPS static host must resolve extensionless paths such as `/focus` to exported HTML. Development uses `npm run web`. Use `/?qa=1` for simulated browser testing. The QA namespace and its first-entry preference are separate from real browser data.

The browser stores focus, breaks, projects, tasks, reflections, history and ideas in IndexedDB. Expo mobile uses the shared TypeScript timer and a SQLite storage adapter. The Swift desktop app retains its own storage format. There is no cross-device synchronization. Browser backup import accepts Tempo Web archives and preserves existing IDs. A browser clock discontinuity can produce an estimated recovery.

The production build generates a content-versioned service worker. On the first successful online load it prepares the offline shell. An update waits for the user before activation and reload. For installation, use the browser's install action or Add to Home Screen. Browser support differs. The production origin requires HTTPS. Localhost can be used for testing.

Mobile currently exposes timer, break, pause/resume, finish and recent sessions. The web-only project, task, analytics and Ideas screens are absent from the mobile UI. Native package and device verification are separate from browser verification.

Official references: [Expo Router SDK 57](https://docs.expo.dev/versions/v57.0.0/sdk/router/), [Expo SQLite SDK 57](https://docs.expo.dev/versions/v57.0.0/sdk/sqlite/), [Expo PWA guide](https://docs.expo.dev/guides/progressive-web-apps/).

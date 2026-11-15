# Testing

The UADS quality workflow checks manifest integrity, dependency installation,
TypeScript types, timer and browser-policy tests, Node coverage and dependency
advisories. It runs on pull requests to testing, beta and main. Packaging remains
in the separate validation and mobile workflows.

Run the validator using Python with jsonschema 4.25.1 installed. Run
`npm run typecheck` and `npm run test:web` for timer changes, and `swift test`
for the native core. Verify web behavior in a real browser and distinguish macOS,
simulator and physical-device runs in reports. The coverage output measures the
tested files as a whole. The changed-line and branch targets in the budget
configuration still need a diff-aware enforcement check.

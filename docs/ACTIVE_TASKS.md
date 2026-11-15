# Active task queue

Scope comes from the request to verify builds, repair discovered failures and apply the new UADS. Process in creation order, except when a dependency or security issue needs priority.

| ID | Order | Priority | Task and dependencies | Status | Evidence and next action |
|---|---:|---|---|---|---|
| TEMPO-001 | 1 | High | Verify native CI outputs from `ccb8fd3` | Verified | Mobile run 43507029286 and macOS run 43507029311. All five archive checks and four mobile checksums passed. |
| TEMPO-002 | 2 | High | Bootstrap schema, registry, quality checks and evidence tracking | Implemented | Structural validator and local tests passed. Remote workflow execution and finer-grained requirement mapping remain open. |
| TEMPO-003 | 3 | High | Enforce persistent task reconciliation under sections 51–52 | Verified | This queue and the AGENTS.md discovery instruction are checked by the validator. |
| TEMPO-004 | 4 | High | Finish onboarding, genuine screenshot tooling and isolated sample mode | Queued | Section 37. Start with the web onboarding state and isolated screenshot fixtures, then implement native counterparts. |
| TEMPO-005 | 5 | High | Finish landing downloads and PWA installation | Queued | Section 39. Add repository link, installation affordance and published-only package discovery. Alternative installers require an actual supported release. |
| TEMPO-006 | 6 | High | Finish release validation and operations compliance | Queued | Sections 40–50. Add measurable runtime gates, screenshot review and evidence automation. Publication requires authorized channels and eligible artifacts. |
| TEMPO-007 | 7 | High | Verify simulator and physical-device runtime | Blocked | This Mac lacks a working Xcode Simulator installation. Device tests require suitable hardware and signed packages. |

Production remains the X-Center release documented in reports/XCENTER_DEPLOYMENT.md. The current work adds repository infrastructure.

Security follow-up TEMPO-008 takes priority over queued feature work. The stricter audit still reports four high and three moderate advisories after compatible remediation. Next, assess each dependency path and test a supported Expo upgrade in isolation. See [compliance evidence](reports/compliance/2026-11-15.md).

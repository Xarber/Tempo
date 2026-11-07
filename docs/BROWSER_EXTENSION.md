# Optional Chromium website focus companion

## Status

Implemented source: Chrome/Chromium Manifest V3 extension, read-only macOS native messaging host, validated rule export from the Tempo app, temporary browser exception and restoration. Policy/protocol tests are automated. **The extension has not been installed into a real browser or verified against actual navigation.** Safari and Firefox integration are not implemented. Chrome 120+ is the declared target; Chromium/Edge require separate host registration and remain unverified.

## Explicit installation

This integration is optional. The timer works without it. Installation gives the extension permission to redirect top-level HTTP(S) GET navigations for configured domains. No content scripts, page contents, typed data, network uploads or browser history logs are used. The local host exposes only the rule list, session UUID, enable flag and a short expiry; never intentions, project names, reflections or credentials.

1. Build and run Tempo. In Settings, add domains, save/apply a profile if desired, and explicitly enable website rules.
2. Open Chrome's extension management screen, enable developer mode and use **Load unpacked** to select `extensions/chromium` from this repository.
3. Copy this extension's 32-character ID from the browser. Register only that ID:

```sh
python3 scripts/install-browser-host.py --extension-id YOUR_ACTUAL_EXTENSION_ID --browser chrome
```

4. Reload the extension and open its toolbar popup. Verify **Connected**. Start a configured focus session, then verify the popup reports active rules and navigate to a configured test domain.

The install script writes a user-local host in `~/Library/Application Support/OpenRecode/Tempo/BrowserHost` and an allowlisted manifest in `Google/Chrome/NativeMessagingHosts`. It never installs/enables an extension or changes browser permissions automatically. A different pre-existing host registration is preserved and causes a clear error. Python 3 is required. Edge/Chromium use `--browser edge` / `--browser chromium` and their own extension ID.

## Rule semantics

- Domain entries include their subdomains, with DNS boundary matching through `requestDomains`.
- ASCII DNS names only, optionally entered with `*.` prefix. The app normalizes to lowercase. URL schemes, paths, ports, IP addresses and single-label hosts are rejected.
- Only top-level HTTP(S) GET navigation redirects. POST forms, subresources and content already open are not blocked.
- During a running focus session, the app writes a short-lived policy atomically and refreshes it every 15 seconds. Pause, finish, abandon, break and explicit quit publish inactive rules.
- Host polls the small policy file once per second. If it is missing, corrupt, oversized, unsupported or expired, it emits an inactive policy. Lease is at most 30 seconds. Host disconnect clears browser session rules.
- Session rules clear on browser shutdown/extension update. No permanent dynamic rules are installed.
- The reminder page provides Return to work and an explicit **Pause website rules for 5 minutes** action. This temporarily suspends all configured website rules, not just one domain. The toolbar popup can resume them early.
- If Tempo crashes, restrictions expire within the lease while the host/browser continue executing. Browser suspension can delay callbacks; disabling the extension always removes its rules. This is supportive friction, not an unbreakable enforcement or parental-control tool.

No direct Finish-session command is exposed to a website or the extension. Users finish through Tempo. There is no unauthenticated HTTP control endpoint.

## Removal and recovery

Disable/remove the extension through the browser to stop its rules immediately. Registration manifest and host files belong to this integration; remove them deliberately after disabling it if desired. Do not delete other native messaging registrations. App website toggle can be disabled independently. No protected system files or browser binaries are modified.

## Tests

```sh
python3 -m unittest discover -s Tests/BrowserTests -p 'test_*.py'
node --test Tests/BrowserTests/policy.test.mjs
```

Python installer tests use `--output-root` in a temporary directory and never register a host in the user's browser. Swift tests cover domain validation, opt-in requirements, pause/break exclusion, lease cap and private-title exclusion. JavaScript tests cover rule generation, expiry, invalid input, snooze and privacy. Real-browser permission, connection, redirect, crash recovery and removal tests remain required before claiming supported blocking.

## Official API references

- [Chrome native messaging](https://developer.chrome.com/docs/extensions/develop/concepts/native-messaging)
- [Chrome declarativeNetRequest](https://developer.chrome.com/docs/extensions/reference/api/declarativeNetRequest/)

The native bridge intentionally has no generic file-access or command-execution protocol.

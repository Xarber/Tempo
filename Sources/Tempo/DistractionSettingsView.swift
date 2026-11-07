// SPDX-License-Identifier: AGPL-3.0-only
import SwiftUI
import TempoCore

struct DistractionSettingsView: View {
    @Bindable var store: AppStore
    @State private var domain = ""
    @State private var profileName = ""
    var body: some View {
        Section("Website focus rules · optional browser extension") {
            Toggle("Activate website rules during focus", isOn: Binding(get: { store.archive.settings.websiteBlockingEnabled ?? false }, set: { value in store.update { $0.settings.websiteBlockingEnabled = value } }))
            HStack { TextField("Domain, e.g. example.com", text: $domain); Button("Add") {
                guard let normalized = DomainPolicy.normalize(domain) else { store.error = "Enter a domain such as example.com, without a scheme, port or path."; return }
                store.update { a in var domains = a.settings.websiteDomains ?? []; if !domains.contains(normalized) { domains.append(normalized) }; a.settings.websiteDomains = domains }; domain = ""
            }.disabled((store.archive.settings.websiteDomains ?? []).count >= 500) }
            ForEach(store.archive.settings.websiteDomains ?? [], id: \.self) { value in HStack { Label(value, systemImage: "globe"); Spacer(); Button("Remove") { store.update { $0.settings.websiteDomains?.removeAll { $0 == value } } } } }
            if let error = store.browserBridgeError { Label(error, systemImage: "exclamationmark.triangle").font(.caption).foregroundStyle(.orange) }
            DisclosureGroup("Installation, privacy & limitations") {
                Text("Requires the Tempo Chromium extension and an explicitly installed local native messaging host. Enabling this toggle alone does not install or verify an extension. Rules cover entered domains and their subdomains. Pausing, finishing or taking a break removes rules; if Tempo stops, rules expire within 30 seconds while the browser runs. No browsing history or private task names are shared. Safari and Firefox integration are not implemented.").font(.caption)
                Text("Setup: docs/BROWSER_EXTENSION.md in the source repository. Browser connection is not verified by the app.").font(.caption)
            }
        }
        Section("Distraction profiles") {
            HStack { TextField("Profile name", text: $profileName); Button("Save current rules") {
                let name = profileName.trimmingCharacters(in: .whitespacesAndNewlines); guard !name.isEmpty else { return }
                store.update { a in var profiles = a.settings.distractionProfiles ?? []; profiles.append(DistractionProfile(name: name, domains: a.settings.websiteDomains ?? [], applicationIDs: a.settings.distractingApps)); a.settings.distractionProfiles = profiles }; profileName = ""
            }.disabled(profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (store.archive.settings.distractionProfiles ?? []).count >= 100) }
            ForEach(store.archive.settings.distractionProfiles ?? []) { profile in HStack {
                Label(profile.name, systemImage: "shield.lefthalf.filled"); Spacer()
                Button("Apply rules") { store.update { $0.settings.websiteDomains = profile.domains; $0.settings.distractingApps = profile.applicationIDs } }
                Button("Remove") { store.update { $0.settings.distractionProfiles?.removeAll { $0.id == profile.id } } }
            } }
            Text("Applying a profile copies its rules. Website blocking and app reminders each require their own explicit enable switch.").font(.caption).foregroundStyle(.secondary)
        }
    }
}

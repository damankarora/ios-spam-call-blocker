import SwiftUI
import CallKit

private let extensionBundleID = "com.damankarora.callblocker.CallDirectoryExtension"

enum ReloadState: Equatable {
    case idle
    case reloading
    case success
    case failure(String)
}

struct ContentView: View {
    @State private var reloadState: ReloadState = .idle
    @State private var enabledStatus: CXCallDirectoryManager.EnabledStatus = .unknown
    @State private var ranges: [BlockRange] = BlockListStore.load()

    var body: some View {
        NavigationStack {
            List {
                Section("Status") {
                    HStack {
                        Text("Extension")
                        Spacer()
                        Text(statusLabel)
                            .foregroundStyle(statusColor)
                    }
                }

                Section {
                    NavigationLink {
                        BlockedRangesView()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Blocked Ranges")
                            Text(ranges.map(\.displayRange).joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    Button {
                        reloadExtension()
                    } label: {
                        if reloadState == .reloading {
                            HStack {
                                ProgressView()
                                Text("Reloading blocklist…")
                            }
                        } else {
                            Text("Reload Blocklist")
                        }
                    }
                    .disabled(reloadState == .reloading)

                    if case .failure(let message) = reloadState {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                    if reloadState == .success {
                        Text("Blocklist reloaded successfully.")
                            .font(.footnote)
                            .foregroundStyle(.green)
                    }
                } footer: {
                    Text("Tap this after every reinstall, or whenever the blocked number range changes, to push the updated list into CallKit.")
                }

                Section("Enable Blocking") {
                    Text("""
                    1. Open Settings → Phone → Call Blocking & Identification
                    2. Turn on the toggle for "CallBlocker"
                    3. Come back here and tap Reload Blocklist
                    """)
                    .font(.callout)

                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            .navigationTitle("Call Blocker")
            .onAppear {
                refreshStatus()
                ranges = BlockListStore.load()
            }
        }
    }

    private var statusLabel: String {
        switch enabledStatus {
        case .enabled: return "Enabled"
        case .disabled: return "Disabled in Settings"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }

    private var statusColor: Color {
        switch enabledStatus {
        case .enabled: return .green
        case .disabled: return .red
        default: return .secondary
        }
    }

    private func refreshStatus() {
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(withIdentifier: extensionBundleID) { status, _ in
            DispatchQueue.main.async {
                enabledStatus = status
            }
        }
    }

    private func reloadExtension() {
        reloadState = .reloading
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: extensionBundleID) { error in
            DispatchQueue.main.async {
                if let error {
                    reloadState = .failure(error.localizedDescription)
                } else {
                    reloadState = .success
                }
                refreshStatus()
            }
        }
    }
}

#Preview {
    ContentView()
}

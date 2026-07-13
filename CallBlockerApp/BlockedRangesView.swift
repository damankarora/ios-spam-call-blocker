import SwiftUI

struct BlockedRangesView: View {
    @State private var ranges: [BlockRange] = BlockListStore.load()
    @State private var showingAddSheet = false

    var body: some View {
        List {
            Section {
                ForEach(ranges) { range in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(range.displayRange)
                        if range.isValid {
                            Text("\(range.entryCount) numbers")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Invalid — country code and prefix must be digits only")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .onDelete(perform: delete)
            } footer: {
                Text("Tap Reload Blocklist on the previous screen after adding, removing, or changing a range.")
            }
        }
        .navigationTitle("Blocked Ranges")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddRangeView { newRange in
                ranges.append(newRange)
                BlockListStore.save(ranges)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        ranges.remove(atOffsets: offsets)
        BlockListStore.save(ranges)
    }
}

private struct AddRangeView: View {
    @Environment(\.dismiss) private var dismiss
    var onAdd: (BlockRange) -> Void

    @State private var countryCode = "91"
    @State private var prefix = ""
    @State private var wildcardDigits = 6

    private var candidate: BlockRange {
        BlockRange(countryCode: countryCode, prefix: prefix, wildcardDigits: wildcardDigits)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Country Code") {
                    TextField("e.g. 91", text: $countryCode)
                        .keyboardType(.numberPad)
                }
                Section("Prefix") {
                    TextField("e.g. 1409", text: $prefix)
                        .keyboardType(.numberPad)
                }
                Section {
                    Stepper(value: $wildcardDigits, in: 1...6) {
                        Text("\(wildcardDigits) wildcard digit\(wildcardDigits == 1 ? "" : "s")")
                    }
                } footer: {
                    Text("Blocks \(candidate.entryCount) numbers, from \(candidate.displayRange.replacingOccurrences(of: String(repeating: "X", count: wildcardDigits), with: String(repeating: "0", count: wildcardDigits))) to \(candidate.displayRange.replacingOccurrences(of: String(repeating: "X", count: wildcardDigits), with: String(repeating: "9", count: wildcardDigits))). Capped at 6 digits (1,000,000 numbers) per range, matching Apple's documented scale for call directory extensions.")
                }
            }
            .navigationTitle("Add Range")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(candidate)
                        dismiss()
                    }
                    .disabled(!candidate.isValid)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        BlockedRangesView()
    }
}

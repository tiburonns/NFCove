import CoreNFC
import SwiftUI

struct CreateView: View {
    @EnvironmentObject private var library: LibraryStore
    @StateObject private var manager = NFCSessionManager()

    @State private var kind: NFCRecordKind = .text
    @State private var value = ""
    @State private var itemName = ""
    @State private var didSave = false

    private var message: NFCNDEFMessage? {
        NDEFBuilder.message(for: kind, value: value)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("create.type.section") {
                    Picker("create.type.label", selection: $kind) {
                        ForEach(NFCRecordKind.allCases) { recordKind in
                            Label {
                                Text(LocalizedStringKey(recordKind.localizationKey))
                            } icon: {
                                Image(systemName: recordKind.icon)
                            }
                            .tag(recordKind)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("create.content.section") {
                    TextField(LocalizedStringKey(kind.placeholderKey), text: $value, axis: .vertical)
                        .textInputAutocapitalization(kind == .text ? .sentences : .never)
                        .autocorrectionDisabled(kind != .text)

                    HStack {
                        Text("create.estimatedSize")
                        Spacer()
                        Text("\(NDEFBuilder.estimatedSize(for: kind, value: value)) B")
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                Section("create.library.section") {
                    TextField("create.library.name.placeholder", text: $itemName)

                    Button {
                        library.add(name: itemName, kind: kind, value: value)
                        didSave = true
                    } label: {
                        Label("create.library.save", systemImage: "books.vertical")
                    }
                    .disabled(message == nil)
                }

                Section {
                    Button {
                        if let message {
                            manager.beginWrite(message: message)
                        }
                    } label: {
                        Label("create.write.button", systemImage: "wave.3.right")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(message == nil || manager.isActive || !manager.isNFCAvailable)
                } footer: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(LocalizedStringKey(manager.statusKey))
                        if let error = manager.lastError {
                            Text(error)
                        }
                    }
                }
            }
            .navigationTitle("create.title")
            .alert("create.library.saved.title", isPresented: $didSave) {
                Button("common.ok", role: .cancel) { }
            } message: {
                Text("create.library.saved.message")
            }
        }
    }
}

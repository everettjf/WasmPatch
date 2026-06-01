import SwiftUI

struct ContentView: View {
    @ObservedObject var controller: PatchController

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WasmPatch")
                .font(.largeTitle).bold()
            Text("Hot-patch an @objc dynamic Swift method at runtime with a WebAssembly payload.")
                .foregroundColor(.secondary)

            GroupBox("DemoService.greeting()") {
                Text(controller.greeting)
                    .font(.title3.monospaced())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .foregroundColor(controller.isPatched ? .green : .primary)
            }

            HStack {
                Button(controller.isPatched ? "Re-apply Patch" : "Apply Patch") {
                    controller.applyPatch()
                }
                .keyboardShortcut(.defaultAction)

                Button("Reset") { controller.reset() }
                    .disabled(!controller.isPatched)
            }

            Text(controller.status)
                .font(.callout)
                .foregroundColor(.secondary)

            GroupBox("Runtime log") {
                ScrollView {
                    Text(controller.log.isEmpty ? "—" : controller.log.joined(separator: "\n"))
                        .font(.caption.monospaced())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(height: 120)
            }
        }
        .padding(24)
        .frame(minWidth: 460, minHeight: 420)
    }
}

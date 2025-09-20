import SwiftUI
import AppKit
import Combine

struct BakedPromptEditor: View {
    var bakedPrompt: BakedPrompt
    @ObservedObject var variant: PromptVariant
    let shot: FilmShot
    @ObservedObject var filmManager: FilmManager
    let onDismiss: () -> Void

    @State private var promptText: String = ""
    @State private var promptName: String = ""
    @State private var selectedGenerator: String = ""
    @State private var isLoading = true
    @State private var hasChanges = false
    @State private var characterCount: Int = 0

    private let generators = ["", "veo", "sora", "luma", "runway", "pika", "other"]

    var body: some View {
        VStack(spacing: 0) {
            // Header with title and metadata
            VStack(spacing: 8) {
                HStack {
                    Text("Edit Baked Prompt")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()

                    // Character count indicator
                    HStack(spacing: 4) {
                        if characterCount > 2015 {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                        Text("\(characterCount) characters")
                            .font(.caption)
                            .foregroundColor(characterCount > 2015 ? .orange : .secondary)

                        if characterCount > 2015 {
                            Text("(Luma limit: 2015)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                HStack(spacing: 16) {
                    // Name field
                    HStack {
                        Text("Name:")
                            .font(.caption)
                        TextField("Prompt Name", text: $promptName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                            .onChange(of: promptName) { _ in
                                hasChanges = true
                            }
                    }

                    // Generator picker
                    HStack {
                        Text("Generator:")
                            .font(.caption)
                        Picker("", selection: $selectedGenerator) {
                            Text("None").tag("")
                            ForEach(generators.filter { !$0.isEmpty }, id: \.self) { gen in
                                Text(gen.capitalized).tag(gen)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                        .onChange(of: selectedGenerator) { _ in
                            hasChanges = true
                        }
                    }

                    Spacer()

                    // Action buttons
                    Button("Copy to Clipboard") {
                        BakedPromptManager.shared.copyToClipboard(promptText)
                    }
                    .buttonStyle(.bordered)

                    Button("Load from Variant") {
                        loadFromVariant()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Text editor
            ScrollView {
                TextEditor(text: $promptText)
                    .font(.system(size: 13, design: .monospaced))
                    .padding(8)
                    .onChange(of: promptText) { newValue in
                        hasChanges = true
                        characterCount = newValue.count
                    }
            }
            .background(Color(NSColor.textBackgroundColor))

            Divider()

            // Footer with save/cancel
            HStack {
                Text("Variant: \(variant.name)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.escape)

                Button("Save") {
                    saveChanges()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasChanges)
                .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 800, height: 600)
        .onAppear {
            loadContent()
        }
    }

    private func loadContent() {
        // Load existing content if available
        if let content = BakedPromptManager.shared.loadBakedPromptContent(for: bakedPrompt) {
            promptText = content
        } else {
            // If no content, load from variant
            loadFromVariant()
        }

        promptName = bakedPrompt.name
        selectedGenerator = bakedPrompt.generator ?? ""
        characterCount = promptText.count
        isLoading = false
        hasChanges = false
    }

    private func loadFromVariant() {
        // Generate full prompt from variant
        let fullPrompt = variant.generateCompletePrompt(
            for: shot,
            plateManager: filmManager.plateManager,
            trackingSystems: filmManager.trackingSystems
        )
        promptText = fullPrompt
        characterCount = fullPrompt.count
        hasChanges = true
    }

    private func saveChanges() {
        // Update the baked prompt metadata
        if let index = variant.bakedPrompts.firstIndex(where: { $0.id == bakedPrompt.id }) {
            variant.bakedPrompts[index].name = promptName
            variant.bakedPrompts[index].modifiedDate = Date()
            variant.bakedPrompts[index].generator = selectedGenerator.isEmpty ? nil : selectedGenerator
        }

        // Save the content to file and metadata
        do {
            try BakedPromptManager.shared.saveBakedPromptContent(promptText, for: bakedPrompt)
            try BakedPromptManager.shared.saveBakedPromptsMetadata(variant.bakedPrompts, for: variant.variantId)

            // Mark shot as dirty and save
            shot.isDirty = true
            filmManager.fileManager.saveShot(shot)

            // Trigger UI updates
            variant.objectWillChange.send()
            shot.objectWillChange.send()
            filmManager.objectWillChange.send()

            print("💾 Saved baked prompt: \(promptName)")
            onDismiss()
        } catch {
            print("❌ Failed to save baked prompt: \(error)")
        }
    }
}

// MARK: - Window Helper
extension BakedPromptEditor {
    static func openInNewWindow(
        bakedPrompt: BakedPrompt,
        variant: PromptVariant,
        shot: FilmShot,
        filmManager: FilmManager
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Baked Prompt Editor - \(bakedPrompt.name)"
        window.center()
        window.isReleasedWhenClosed = false

        let hostingController = NSHostingController(
            rootView: BakedPromptEditor(
                bakedPrompt: bakedPrompt,
                variant: variant,
                shot: shot,
                filmManager: filmManager,
                onDismiss: {
                    window.close()
                }
            )
        )

        window.contentViewController = hostingController
        window.makeKeyAndOrderFront(nil)
    }
}
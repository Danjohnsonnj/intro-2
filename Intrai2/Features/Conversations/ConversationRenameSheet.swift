import SwiftData
import SwiftUI

struct ConversationRenameSheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var conversation: Conversation
    @State private var draft: String

    init(conversation: Conversation) {
        self.conversation = conversation
        _draft = State(initialValue: conversation.title)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextField("Title", text: $draft)
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.textPrimary(colorScheme))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Theme.surface(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                            .strokeBorder(Theme.border(colorScheme), lineWidth: 1)
                    }
                    .submitLabel(.done)
                    .onSubmit(save)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, Theme.Spacing.screenHorizontal)
            .padding(.top, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background(colorScheme))
            .navigationTitle("Rename")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        ConversationTitleEditing.applyManualRename(
            to: conversation,
            title: draft,
            in: modelContext
        )
    }
}

import SwiftUI

struct SelectionCard: View {
    let selection: CandidateSelection
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(value: Route.candidateID(selection.candidateId)) {
                HStack(spacing: 12) {
                    RemoteLogo(
                        urlString: selection.candidatePhotoUrl,
                        systemImage: "person.crop.circle.fill",
                        size: 64
                    )
                    VStack(alignment: .leading, spacing: 3) {
                        Text(selection.candidateName)
                            .font(.headline)
                        Text(selection.positionName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Label(selection.municipalityName, systemImage: "mappin.and.ellipse")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(selection.notes.isEmpty ? "No notes" : selection.notes)
                .font(.subheadline)
                .foregroundColor(selection.notes.isEmpty ? .secondary : .primary)
                .italic(selection.notes.isEmpty)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 2) {
                Text("Saved \(selection.dateCreated.formatted(date: .abbreviated, time: .shortened))")
                if selection.wasEdited {
                    Text("Edited \(selection.dateModified.formatted(date: .abbreviated, time: .shortened))")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .cardStyle()
        .contextMenu {
            Button(action: onEdit) { Label("Edit Selection", systemImage: "pencil") }
            Button(role: .destructive, action: onDelete) { Label("Delete Selection", systemImage: "trash") }
        }
    }
}

#if DEBUG
struct SelectionCard_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(PreviewData.selections) { selection in
                        SelectionCard(selection: selection, onEdit: {}, onDelete: {})
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}
#endif

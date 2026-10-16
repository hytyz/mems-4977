import SwiftUI

/// Candidate detail: biography, contact links, and the "Add to Voting Guide"
/// action (disabled once the candidate is already saved).
struct CandidateDetailView: View {
    let candidate: Candidate
    @EnvironmentObject private var votingGuideViewModel: VotingGuideViewModel

    var body: some View {
        List {
            Section("Candidate") {
                HStack(spacing: 14) {
                    RemoteLogo(
                        urlString: candidate.photoUrl,
                        systemImage: "person.crop.circle.fill",
                        size: 64
                    )
                    Text(candidate.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                if let biography = candidate.biography, !biography.isEmpty {
                    Text(biography)
                        .font(.body)
                }
            }

            Section("Contact") {
                websiteLink
                emailLink
            }

            Section("Voting Guide") {
                if votingGuideViewModel.isSaved(candidateId: candidate.id) {
                    Label("Already in your voting guide", systemImage: "checkmark.seal.fill")
                        .foregroundColor(.green)
                } else {
                    Button {
                        Task { await votingGuideViewModel.save(candidate: candidate) }
                    } label: {
                        if votingGuideViewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Add to Voting Guide", systemImage: "star")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(votingGuideViewModel.isLoading)
                }

                if let feedback = votingGuideViewModel.lastSaveFeedback {
                    Label(feedback, systemImage: "checkmark.circle")
                        .font(.footnote)
                        .foregroundColor(.green)
                }
                if let message = votingGuideViewModel.errorMessage {
                    ErrorMessageView(message: message)
                }
            }
        }
        .navigationTitle(candidate.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var websiteLink: some View {
        if let website = candidate.website?.trimmed,
           !website.isEmpty,
           let url = URL(string: website),
           url.scheme != nil {
            Link(destination: url) {
                Label(website, systemImage: "globe")
            }
        } else {
            Text("No website provided")
                .foregroundColor(.secondary)
        }
    }

    @ViewBuilder
    private var emailLink: some View {
        if let email = candidate.email?.trimmed, !email.isEmpty {
            if let url = URL(string: "mailto:\(email)") {
                Link(destination: url) {
                    Label(email, systemImage: "envelope")
                }
            } else {
                Text(email)
            }
        } else {
            Text("No email provided")
                .foregroundColor(.secondary)
        }
    }
}

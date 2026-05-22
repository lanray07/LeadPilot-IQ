import SwiftData
import SwiftUI

struct ProposalCenterView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Proposal.createdAt, order: .reverse) private var proposals: [Proposal]
    @Query private var leads: [Lead]
    @Query private var profiles: [BusinessProfile]

    @State private var viewModel = ProposalCenterViewModel()
    @State private var statusFilter: ProposalStatus?
    @State private var editingProposal: Proposal?
    @State private var shareItem: ShareItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                filterBar

                if filteredProposals.isEmpty {
                    EmptyStateView(
                        systemImage: "folder.badge.plus",
                        title: "No proposals yet",
                        message: "Generate and save a quote to build your proposal library."
                    ) {
                        NavigationLink(value: AppRoute.quote(nil)) {
                            Label("Generate Quote", systemImage: "doc.badge.plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.lpBlue)
                    }
                } else {
                    ForEach(filteredProposals) { proposal in
                        VStack(alignment: .leading, spacing: 10) {
                            ProposalCard(proposal: proposal, leadName: leadName(for: proposal))
                            HStack {
                                Button {
                                    editingProposal = proposal
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Menu {
                                    ForEach(ProposalStatus.allCases) { status in
                                        Button(status.displayName) {
                                            update(proposal, status: status)
                                        }
                                    }
                                } label: {
                                    Label("Status", systemImage: "line.3.horizontal.decrease.circle")
                                }

                                Button {
                                    duplicate(proposal)
                                } label: {
                                    Label("Duplicate", systemImage: "doc.on.doc")
                                }

                                Button {
                                    export(proposal)
                                } label: {
                                    Label("PDF", systemImage: "square.and.arrow.up")
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Proposals")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.quote(nil)) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Generate Proposal")
            }
        }
        .sheet(item: $editingProposal) { proposal in
            NavigationStack {
                ProposalEditorView(proposal: proposal)
            }
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
    }

    private var filterBar: some View {
        HStack {
            Menu {
                Button("All proposals") { statusFilter = nil }
                ForEach(ProposalStatus.allCases) { status in
                    Button(status.displayName) { statusFilter = status }
                }
            } label: {
                Label(statusFilter?.displayName ?? "All proposals", systemImage: "slider.horizontal.3")
            }
            .buttonStyle(.bordered)

            Spacer()

            Text("\(filteredProposals.count) saved")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var filteredProposals: [Proposal] {
        proposals.filter { statusFilter == nil || $0.status == statusFilter }
    }

    private func leadName(for proposal: Proposal) -> String? {
        guard let leadId = proposal.leadId else { return nil }
        return leads.first(where: { $0.id == leadId })?.name
    }

    private func lead(for proposal: Proposal) -> Lead? {
        guard let leadId = proposal.leadId else { return nil }
        return leads.first(where: { $0.id == leadId })
    }

    private func duplicate(_ proposal: Proposal) {
        do {
            try viewModel.duplicate(proposal, in: modelContext)
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func update(_ proposal: Proposal, status: ProposalStatus) {
        do {
            try viewModel.updateStatus(proposal, status: status, in: modelContext)
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func export(_ proposal: Proposal) {
        do {
            let url = try PDFProposalService.render(
                proposal: proposal,
                lead: lead(for: proposal),
                profile: ProfileResolver.currentProfile(from: profiles)
            )
            proposal.pdfLocalURL = url
            try modelContext.save()
            shareItem = ShareItem(url: url)
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

private struct ProposalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var proposal: Proposal

    var body: some View {
        Form {
            Section("Proposal") {
                TextField("Title", text: $proposal.title)
                TextField("Estimated value", value: $proposal.estimatedValue, format: .currency(code: "GBP"))
                    .keyboardType(.decimalPad)
                Picker("Status", selection: $proposal.statusRaw) {
                    ForEach(ProposalStatus.allCases) { status in
                        Text(status.displayName).tag(status.rawValue)
                    }
                }
            }

            Section("Content") {
                TextEditor(text: $proposal.content)
                    .frame(minHeight: 320)
            }
        }
        .navigationTitle("Edit Proposal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    try? modelContext.save()
                    dismiss()
                }
            }
        }
    }
}

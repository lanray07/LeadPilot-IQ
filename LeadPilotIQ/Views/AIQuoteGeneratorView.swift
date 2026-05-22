import SwiftData
import SwiftUI

struct AIQuoteGeneratorView: View {
    let initialLeadID: UUID?

    @Environment(\.aiService) private var aiService
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionService.self) private var subscriptionService

    @Query(sort: \Lead.createdAt, order: .reverse) private var leads: [Lead]
    @Query(sort: \QualificationResult.createdAt, order: .reverse) private var qualifications: [QualificationResult]
    @Query private var profiles: [BusinessProfile]

    @State private var selectedLeadID: UUID?
    @State private var viewModel = QuoteViewModel()
    @State private var shareItem: ShareItem?
    @State private var statusMessage: String?

    init(initialLeadID: UUID?) {
        self.initialLeadID = initialLeadID
        _selectedLeadID = State(initialValue: initialLeadID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !subscriptionService.isActive {
                    UpgradeBanner(feature: "AI proposal generation and PDF exports are included with Pro.")
                }

                if leads.isEmpty {
                    EmptyStateView(systemImage: "doc.badge.plus", title: "No lead selected", message: "Add a lead before generating a quote.") {
                        NavigationLink(value: AppRoute.addLead) {
                            Label("Add Lead", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.lpBlue)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        LeadPicker(leads: leads, selectedLeadID: $selectedLeadID)
                        if let selectedLead {
                            LeadCard(lead: selectedLead, qualification: latestQualification)
                        }
                    }

                    Button {
                        Task { await generate() }
                    } label: {
                        Label("Generate proposal", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.lpBlue)
                    .disabled(selectedLead == nil || viewModel.isLoading)

                    if viewModel.isLoading {
                        LoadingOverlay(title: "Drafting proposal")
                    }

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                    }

                    proposalEditor
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("AI Quote Generator")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
    }

    private var selectedLead: Lead? {
        if let selectedLeadID, let lead = leads.first(where: { $0.id == selectedLeadID }) {
            return lead
        }
        return leads.first
    }

    private var latestQualification: QualificationResult? {
        guard let selectedLead else { return nil }
        return qualifications.first(where: { $0.leadId == selectedLead.id })
    }

    private var currentProfile: BusinessProfile? {
        ProfileResolver.currentProfile(from: profiles)
    }

    private var proposalEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Editable proposal")
                .font(.headline)

            TextField("Proposal title", text: $viewModel.editableTitle)
                .textInputAutocapitalization(.words)

            TextField("Estimated value", value: $viewModel.estimatedValue, format: .currency(code: "GBP"))
                .keyboardType(.decimalPad)

            TextEditor(text: $viewModel.editableContent)
                .frame(minHeight: 320)
                .padding(8)
                .background(Color.lpSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                Button {
                    save()
                } label: {
                    Label("Save", systemImage: "tray.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .tint(.lpGreen)
                .disabled(!viewModel.hasGeneratedDraft)

                Button {
                    saveTemplate()
                } label: {
                    Label("Template", systemImage: "bookmark")
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.hasGeneratedDraft)

                Button {
                    exportPDF()
                } label: {
                    Label("Export PDF", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.hasGeneratedDraft)
            }

            if let statusMessage {
                Label(statusMessage, systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.lpGreen)
            }
        }
        .cardStyle()
    }

    private func generate() async {
        guard let selectedLead else { return }
        await viewModel.generate(
            lead: selectedLead,
            businessType: ProfileResolver.businessType(from: profiles),
            qualification: latestQualification,
            aiService: aiService
        )
        statusMessage = nil
    }

    private func save() {
        do {
            _ = try viewModel.saveProposal(for: selectedLead, in: modelContext)
            statusMessage = "Proposal saved."
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func saveTemplate() {
        do {
            _ = try viewModel.saveTemplate(in: modelContext)
            statusMessage = "Template saved."
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    private func exportPDF() {
        do {
            let proposal = try viewModel.saveProposal(for: selectedLead, in: modelContext)
            let url = try PDFProposalService.render(proposal: proposal, lead: selectedLead, profile: currentProfile)
            proposal.pdfLocalURL = url
            try modelContext.save()
            shareItem = ShareItem(url: url)
            statusMessage = "PDF exported."
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

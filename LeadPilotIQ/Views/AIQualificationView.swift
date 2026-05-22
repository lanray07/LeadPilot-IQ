import SwiftData
import SwiftUI

struct AIQualificationView: View {
    let initialLeadID: UUID?

    @Environment(\.aiService) private var aiService
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionService.self) private var subscriptionService

    @Query(sort: \Lead.createdAt, order: .reverse) private var leads: [Lead]
    @Query private var profiles: [BusinessProfile]
    @Query(sort: \LeadPhoto.createdAt, order: .reverse) private var photos: [LeadPhoto]

    @State private var selectedLeadID: UUID?
    @State private var viewModel = QualificationViewModel()
    @State private var savedResultMessage: String?

    init(initialLeadID: UUID?) {
        self.initialLeadID = initialLeadID
        _selectedLeadID = State(initialValue: initialLeadID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !subscriptionService.isActive {
                    UpgradeBanner(feature: "AI qualification scoring is included with Pro and Business plans.")
                }

                if leads.isEmpty {
                    EmptyStateView(
                        systemImage: "person.crop.circle.badge.plus",
                        title: "No leads to qualify",
                        message: "Add a lead first, then generate a score and recommended next action."
                    ) {
                        NavigationLink(value: AppRoute.addLead) {
                            Label("Add Lead", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.lpBlue)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        LeadPicker(leads: leads, selectedLeadID: $selectedLeadID)
                        selectedLead.map { LeadCard(lead: $0, qualification: nil) }
                    }

                    Button {
                        Task { await qualify() }
                    } label: {
                        Label("Generate AI qualification", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.lpBlue)
                    .disabled(selectedLead == nil || viewModel.isLoading)

                    if viewModel.isLoading {
                        LoadingOverlay(title: "Reviewing lead details")
                    }

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                    }

                    if let result = viewModel.result {
                        qualificationResult(result)
                    }

                    DisclaimerBlock()
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("AI Qualification")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var selectedLead: Lead? {
        if let selectedLeadID, let lead = leads.first(where: { $0.id == selectedLeadID }) {
            return lead
        }
        return leads.first
    }

    private func qualify() async {
        guard let selectedLead else { return }
        let leadPhotos = photos.filter { $0.leadId == selectedLead.id }
        await viewModel.qualify(
            lead: selectedLead,
            businessType: ProfileResolver.businessType(from: profiles),
            photos: leadPhotos,
            aiService: aiService
        )
        savedResultMessage = nil
    }

    private func saveResult() {
        guard let selectedLead else { return }
        do {
            _ = try viewModel.saveResult(for: selectedLead, in: modelContext)
            savedResultMessage = "Qualification saved to lead."
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }

    @ViewBuilder
    private func qualificationResult(_ result: AILeadQualification) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lead quality score")
                        .font(.headline)
                    Text(result.category.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                LeadScoreBadge(score: result.leadScore, category: result.category)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                MetricTile(title: "Project value", value: result.projectValueEstimate.currencyFormatted, systemImage: "sterlingsign.circle", tint: .lpGreen)
                MetricTile(title: "Likelihood", value: result.conversionLikelihood.percentFormatted, systemImage: "chart.line.uptrend.xyaxis", tint: .lpBlue)
            }

            VStack(alignment: .leading, spacing: 8) {
                Label("Recommended next action", systemImage: "arrowshape.turn.up.right")
                    .font(.headline)
                Text(result.recommendedAction)
                    .font(.subheadline)
                Label(result.followUpTimingSuggestion, systemImage: "clock.badge.checkmark")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                saveResult()
            } label: {
                Label("Save qualification", systemImage: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.lpGreen)

            if let savedResultMessage {
                Label(savedResultMessage, systemImage: "checkmark.seal")
                    .font(.subheadline)
                    .foregroundStyle(.lpGreen)
            }
        }
        .cardStyle()
    }
}

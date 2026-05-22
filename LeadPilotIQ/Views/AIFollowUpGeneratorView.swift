import SwiftData
import SwiftUI

struct AIFollowUpGeneratorView: View {
    let initialLeadID: UUID?

    @Environment(\.aiService) private var aiService
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionService.self) private var subscriptionService
    @AppStorage("defaultFollowUpTone") private var defaultFollowUpTone = FollowUpTone.professional.rawValue

    @Query(sort: \Lead.createdAt, order: .reverse) private var leads: [Lead]
    @Query(sort: \QualificationResult.createdAt, order: .reverse) private var qualifications: [QualificationResult]

    @State private var selectedLeadID: UUID?
    @State private var viewModel = FollowUpViewModel()
    @State private var statusMessage: String?

    init(initialLeadID: UUID?) {
        self.initialLeadID = initialLeadID
        _selectedLeadID = State(initialValue: initialLeadID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !subscriptionService.isActive {
                    UpgradeBanner(feature: "AI follow-ups, objection handling, and reminders are included with Pro.")
                }

                if leads.isEmpty {
                    EmptyStateView(systemImage: "bubble.left.and.text.bubble.right", title: "No leads available", message: "Add a lead before generating follow-up messages.") {
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

                    followUpControls

                    if viewModel.isLoading {
                        LoadingOverlay(title: "Writing follow-up")
                    }

                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error)
                    }

                    generatedMessage
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("AI Follow-Up")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.tone = FollowUpTone(rawValue: defaultFollowUpTone) ?? .professional
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

    private var followUpControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("Message type", selection: $viewModel.type) {
                ForEach(FollowUpType.allCases) { type in
                    Text(type.displayName).tag(type)
                }
            }

            Picker("Tone", selection: $viewModel.tone) {
                ForEach(FollowUpTone.allCases) { tone in
                    Text(tone.displayName).tag(tone)
                }
            }
            .pickerStyle(.segmented)

            TextField("Context or objection to handle", text: $viewModel.context, axis: .vertical)
                .lineLimit(2...4)

            Button {
                Task { await generate() }
            } label: {
                Label("Generate follow-up", systemImage: "sparkles")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.lpBlue)
            .disabled(selectedLead == nil || viewModel.isLoading)
        }
        .cardStyle()
    }

    private var generatedMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generated message")
                .font(.headline)
            TextEditor(text: $viewModel.generatedContent)
                .frame(minHeight: 220)
                .padding(8)
                .background(Color.lpSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            Button {
                save()
            } label: {
                Label("Save follow-up", systemImage: "tray.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.lpGreen)
            .disabled(!viewModel.canSave)

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
        await viewModel.generate(lead: selectedLead, aiService: aiService)
        statusMessage = nil
    }

    private func save() {
        do {
            _ = try viewModel.save(for: selectedLead, in: modelContext)
            statusMessage = "Follow-up saved."
        } catch {
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

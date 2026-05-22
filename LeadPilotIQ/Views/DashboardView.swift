import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(SubscriptionService.self) private var subscriptionService
    @Query(sort: \Lead.createdAt, order: .reverse) private var leads: [Lead]
    @Query(sort: \Proposal.createdAt, order: .reverse) private var proposals: [Proposal]
    @Query(sort: \QualificationResult.createdAt, order: .reverse) private var qualifications: [QualificationResult]
    @Query(sort: \FollowUpMessage.createdAt, order: .reverse) private var followUps: [FollowUpMessage]

    @State private var viewModel = DashboardViewModel()

    private let actionColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                PipelineSummaryView(
                    metrics: viewModel.metrics(
                        leads: leads,
                        proposals: proposals,
                        qualifications: qualifications,
                        followUps: followUps
                    ),
                    subscriptionLabel: subscriptionService.currentPlan.displayName
                )

                if !subscriptionService.isActive {
                    UpgradeBanner(feature: "Unlock unlimited leads, AI scoring, proposal exports, analytics, and voice-to-lead conversion.")
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick actions")
                        .font(.headline)
                    LazyVGrid(columns: actionColumns, spacing: 12) {
                        QuickActionButton(title: "Add Lead", systemImage: "plus", tint: .lpBlue, route: .addLead)
                        QuickActionButton(title: "AI Qualification", systemImage: "sparkles", tint: .lpGreen, route: .qualification(nil))
                        QuickActionButton(title: "Generate Quote", systemImage: "doc.badge.plus", tint: .orange, route: .quote(nil))
                        QuickActionButton(title: "Follow-Up Generator", systemImage: "bubble.left.and.text.bubble.right", tint: .purple, route: .followUp(nil))
                        QuickActionButton(title: "Voice Note to Lead", systemImage: "mic", tint: .red, route: .voiceNote)
                        QuickActionButton(title: "Saved Proposals", systemImage: "folder", tint: .lpBlue, route: .proposalCenter)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent leads")
                            .font(.headline)
                        Spacer()
                        NavigationLink("Add", value: AppRoute.addLead)
                            .font(.caption.weight(.semibold))
                    }

                    if leads.isEmpty {
                        EmptyStateView(
                            systemImage: "person.crop.circle.badge.plus",
                            title: "No leads yet",
                            message: "Capture your first enquiry and LeadPilot IQ will help qualify it."
                        ) {
                            NavigationLink(value: AppRoute.addLead) {
                                Label("Add Lead", systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.lpBlue)
                        }
                    } else {
                        ForEach(leads.prefix(4)) { lead in
                            NavigationLink(value: AppRoute.leadDetail(lead.id)) {
                                LeadCard(lead: lead, qualification: latestQualification(for: lead))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Dashboard")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pipeline command center")
                .font(.title2.bold())
            Text("Track enquiries, quote faster, and focus on the leads most likely to convert.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func latestQualification(for lead: Lead) -> QualificationResult? {
        qualifications
            .filter { $0.leadId == lead.id }
            .max(by: { $0.createdAt < $1.createdAt })
    }
}

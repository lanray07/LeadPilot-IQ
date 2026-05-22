import SwiftData
import SwiftUI

struct LeadListView: View {
    @Query(sort: \Lead.createdAt, order: .reverse) private var leads: [Lead]
    @Query(sort: \QualificationResult.createdAt, order: .reverse) private var qualifications: [QualificationResult]

    @State private var searchText = ""
    @State private var statusFilter: LeadStatus?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                filterBar

                if filteredLeads.isEmpty {
                    EmptyStateView(
                        systemImage: "tray",
                        title: "No matching leads",
                        message: "Add a lead or adjust the current search and status filter."
                    ) {
                        NavigationLink(value: AppRoute.addLead) {
                            Label("Add Lead", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.lpBlue)
                    }
                } else {
                    ForEach(filteredLeads) { lead in
                        NavigationLink(value: AppRoute.leadDetail(lead.id)) {
                            LeadCard(lead: lead, qualification: latestQualification(for: lead))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Leads")
        .searchable(text: $searchText, prompt: "Search leads")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(value: AppRoute.addLead) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Lead")
            }
        }
    }

    private var filterBar: some View {
        HStack {
            Menu {
                Button("All statuses") { statusFilter = nil }
                ForEach(LeadStatus.allCases) { status in
                    Button(status.displayName) { statusFilter = status }
                }
            } label: {
                Label(statusFilter?.displayName ?? "All statuses", systemImage: "line.3.horizontal.decrease.circle")
            }
            .buttonStyle(.bordered)

            Spacer()

            Text("\(filteredLeads.count) leads")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var filteredLeads: [Lead] {
        leads.filter { lead in
            let matchesStatus = statusFilter == nil || lead.status == statusFilter
            guard !searchText.isEmpty else { return matchesStatus }
            let searchBlob = "\(lead.name) \(lead.serviceRequested) \(lead.email) \(lead.phone) \(lead.location) \(lead.notes)".lowercased()
            return matchesStatus && searchBlob.contains(searchText.lowercased())
        }
    }

    private func latestQualification(for lead: Lead) -> QualificationResult? {
        qualifications
            .filter { $0.leadId == lead.id }
            .max(by: { $0.createdAt < $1.createdAt })
    }
}

struct LeadDetailView: View {
    let leadID: UUID

    @Query private var leads: [Lead]
    @Query(sort: \LeadPhoto.createdAt, order: .reverse) private var photos: [LeadPhoto]
    @Query(sort: \QualificationResult.createdAt, order: .reverse) private var qualifications: [QualificationResult]
    @Query(sort: \Proposal.createdAt, order: .reverse) private var proposals: [Proposal]
    @Query(sort: \FollowUpMessage.createdAt, order: .reverse) private var followUps: [FollowUpMessage]

    var body: some View {
        if let lead = leads.first(where: { $0.id == leadID }) {
            LeadDetailContent(
                lead: lead,
                photos: photos.filter { $0.leadId == leadID },
                qualifications: qualifications.filter { $0.leadId == leadID },
                proposals: proposals.filter { $0.leadId == leadID },
                followUps: followUps.filter { $0.leadId == leadID }
            )
        } else {
            EmptyStateView(systemImage: "questionmark.folder", title: "Lead not found", message: "This lead may have been deleted.")
                .padding()
                .navigationTitle("Lead")
        }
    }
}

private struct LeadDetailContent: View {
    @Bindable var lead: Lead
    var photos: [LeadPhoto]
    var qualifications: [QualificationResult]
    var proposals: [Proposal]
    var followUps: [FollowUpMessage]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(lead.name)
                                .font(.title2.bold())
                            Text(lead.serviceRequested)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        LeadScoreBadge(score: qualifications.first?.leadScore, category: qualifications.first?.category)
                    }

                    HStack(spacing: 8) {
                        NavigationLink(value: AppRoute.qualification(lead.id)) {
                            Label("Qualify", systemImage: "sparkles")
                        }
                        NavigationLink(value: AppRoute.quote(lead.id)) {
                            Label("Quote", systemImage: "doc.badge.plus")
                        }
                        NavigationLink(value: AppRoute.followUp(lead.id)) {
                            Label("Follow up", systemImage: "bubble.left")
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Lead details")
                        .font(.headline)
                    TextField("Phone", text: $lead.phone)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $lead.email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    TextField("Location", text: $lead.location)
                    TextField("Budget range", text: $lead.budgetRange)
                    Picker("Urgency", selection: $lead.urgencyRaw) {
                        ForEach(LeadUrgency.allCases) { urgency in
                            Text(urgency.displayName).tag(urgency.rawValue)
                        }
                    }
                    Picker("Status", selection: $lead.statusRaw) {
                        ForEach(LeadStatus.allCases) { status in
                            Text(status.displayName).tag(status.rawValue)
                        }
                    }
                    TextEditor(text: $lead.notes)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color.lpSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .cardStyle()

                if !photos.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Photos")
                            .font(.headline)
                        StoredPhotoGrid(photos: photos)
                    }
                    .cardStyle()
                }

                relatedSection
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Lead")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var relatedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)

            if proposals.isEmpty && followUps.isEmpty && qualifications.isEmpty {
                Text("No AI activity has been saved for this lead yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.lpSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            ForEach(proposals.prefix(2)) { proposal in
                ProposalCard(proposal: proposal, leadName: lead.name)
            }

            ForEach(followUps.prefix(2)) { followUp in
                FollowUpCard(message: followUp, leadName: lead.name)
            }
        }
    }
}

import SwiftUI
import UIKit

extension Color {
    static let lpCharcoal = Color(red: 0.09, green: 0.10, blue: 0.12)
    static let lpBlue = Color(red: 0.08, green: 0.34, blue: 0.85)
    static let lpGreen = Color(red: 0.00, green: 0.58, blue: 0.45)
    static let lpSurface = Color(.secondarySystemBackground)
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

struct LeadScoreBadge: View {
    var score: Int?
    var category: LeadCategory?

    private var label: String {
        if let score {
            "\(score)"
        } else {
            "New"
        }
    }

    private var color: Color {
        guard let score else { return .secondary }
        if score >= 80 { return .lpGreen }
        if score >= 60 { return .lpBlue }
        if score >= 40 { return .orange }
        return .red
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: score == nil ? "sparkles" : "gauge")
            Text(label)
                .fontWeight(.semibold)
            if let category {
                Text(category.displayName)
                    .font(.caption)
            }
        }
        .font(.caption)
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityLabel("Lead score \(label)")
    }
}

struct StatusPill: View {
    var title: String
    var systemImage: String
    var color: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(color)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct MetricTile: View {
    var title: String
    var value: String
    var systemImage: String
    var tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
                Spacer()
            }
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct QuickActionButton: View {
    var title: String
    var systemImage: String
    var tint: Color
    var route: AppRoute

    var body: some View {
        NavigationLink(value: route) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct LeadCard: View {
    var lead: Lead
    var qualification: QualificationResult?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lead.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(lead.serviceRequested)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer(minLength: 12)
                LeadScoreBadge(score: qualification?.leadScore, category: qualification?.category)
            }

            HStack(spacing: 8) {
                StatusPill(title: lead.status.displayName, systemImage: "line.3.horizontal.decrease.circle", color: .lpBlue)
                StatusPill(title: lead.urgency.displayName, systemImage: "clock", color: lead.urgency == .emergency ? .red : .lpGreen)
            }

            HStack {
                Label(lead.source.displayName, systemImage: "point.3.connected.trianglepath.dotted")
                Spacer()
                Text(lead.createdAt.shortFormatted)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .cardStyle()
    }
}

struct ProposalCard: View {
    var proposal: Proposal
    var leadName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(proposal.title)
                        .font(.headline)
                        .lineLimit(2)
                    if let leadName {
                        Text(leadName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 12)
                StatusPill(title: proposal.status.displayName, systemImage: statusIcon, color: statusColor)
            }

            Text(proposal.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack {
                Label(proposal.estimatedValue.currencyFormatted, systemImage: "sterlingsign.circle")
                Spacer()
                Text(proposal.createdAt.shortFormatted)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .cardStyle()
    }

    private var statusColor: Color {
        switch proposal.status {
        case .draft: .secondary
        case .sent: .lpBlue
        case .accepted: .lpGreen
        case .rejected: .red
        }
    }

    private var statusIcon: String {
        switch proposal.status {
        case .draft: "doc.text"
        case .sent: "paperplane"
        case .accepted: "checkmark.seal"
        case .rejected: "xmark.seal"
        }
    }
}

struct FollowUpCard: View {
    var message: FollowUpMessage
    var leadName: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                StatusPill(title: message.type.displayName, systemImage: "bubble.left.and.text.bubble.right", color: .lpBlue)
                StatusPill(title: message.tone.displayName, systemImage: "slider.horizontal.3", color: .lpGreen)
                Spacer()
            }

            Text(message.content)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(5)

            HStack {
                if let leadName {
                    Label(leadName, systemImage: "person")
                }
                Spacer()
                Text(message.createdAt.shortFormatted)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .cardStyle()
    }
}

struct AnalyticsChartCard<Content: View>: View {
    var title: String
    var subtitle: String
    @ViewBuilder var content: Content

    init(title: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            content
                .frame(minHeight: 210)
        }
        .cardStyle()
    }
}

struct PipelineSummaryView: View {
    var metrics: DashboardMetrics
    var subscriptionLabel: String

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            MetricTile(title: "New leads", value: "\(metrics.newLeads)", systemImage: "tray.and.arrow.down", tint: .lpBlue)
            MetricTile(title: "Hot leads", value: "\(metrics.hotLeads)", systemImage: "flame", tint: .orange)
            MetricTile(title: "Quotes sent", value: "\(metrics.quotesSent)", systemImage: "doc.text", tint: .lpGreen)
            MetricTile(title: "Follow-ups", value: "\(metrics.pendingFollowUps)", systemImage: "bell.badge", tint: .purple)
            MetricTile(title: "Conversion", value: metrics.conversionRate.percentFormatted, systemImage: "chart.line.uptrend.xyaxis", tint: .lpBlue)
            MetricTile(title: "Pipeline", value: metrics.estimatedPipelineValue.currencyFormatted, systemImage: "sterlingsign.circle", tint: .lpGreen)
        }

        HStack {
            Label(subscriptionLabel, systemImage: "creditcard")
                .font(.subheadline.weight(.semibold))
            Spacer()
            NavigationLink(value: AppRoute.paywall) {
                Label("Plans", systemImage: "arrow.up.right")
                    .font(.caption.weight(.semibold))
            }
        }
        .padding(14)
        .background(Color.lpBlue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct UpgradeBanner: View {
    var feature: String

    var body: some View {
        NavigationLink(value: AppRoute.paywall) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.lpGreen)
                    .frame(width: 34, height: 34)
                    .background(Color.lpGreen.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Pro feature")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.lpGreen)
                    Text(feature)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color.lpGreen.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateView<Action: View>: View {
    var systemImage: String
    var title: String
    var message: String
    @ViewBuilder var action: Action

    init(
        systemImage: String,
        title: String,
        message: String,
        @ViewBuilder action: () -> Action
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.action = action()
    }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(Color.lpBlue)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            action
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.lpSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension EmptyStateView where Action == EmptyView {
    init(systemImage: String, title: String, message: String) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.action = EmptyView()
    }
}

struct DisclaimerBlock: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Important disclaimer", systemImage: "exclamationmark.shield")
                .font(.headline)
            ForEach(AppConstants.disclaimers, id: \.self) { disclaimer in
                Label(disclaimer, systemImage: "checkmark.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.orange.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct LeadPicker: View {
    var leads: [Lead]
    @Binding var selectedLeadID: UUID?

    var body: some View {
        Picker("Lead", selection: $selectedLeadID) {
            Text("Select a lead").tag(UUID?.none)
            ForEach(leads) { lead in
                Text("\(lead.name) - \(lead.serviceRequested)").tag(Optional(lead.id))
            }
        }
        .pickerStyle(.menu)
        .onAppear {
            if selectedLeadID == nil {
                selectedLeadID = leads.first?.id
            }
        }
    }
}

struct PhotoThumbnailGrid: View {
    var drafts: [LeadPhotoDraft]

    private let columns = [
        GridItem(.adaptive(minimum: 74), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(drafts) { draft in
                if let image = UIImage(data: draft.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 74)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .accessibilityLabel("Lead photo")
                }
            }
        }
    }
}

struct StoredPhotoGrid: View {
    var photos: [LeadPhoto]

    private let columns = [
        GridItem(.adaptive(minimum: 82), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(photos) { photo in
                if let data = photo.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 82)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
    }
}

struct LoadingOverlay: View {
    var title: String

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(title)
                .font(.subheadline.weight(.medium))
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color.lpSurface)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct ErrorBanner: View {
    var message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.subheadline)
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Color.red.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

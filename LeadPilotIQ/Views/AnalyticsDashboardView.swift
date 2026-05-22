import Charts
import SwiftData
import SwiftUI

struct AnalyticsDashboardView: View {
    @Environment(\.aiService) private var aiService

    @Query(sort: \Lead.createdAt, order: .reverse) private var leads: [Lead]
    @Query(sort: \Proposal.createdAt, order: .reverse) private var proposals: [Proposal]
    @Query(sort: \FollowUpMessage.createdAt, order: .reverse) private var followUps: [FollowUpMessage]
    @Query private var profiles: [BusinessProfile]

    @State private var viewModel = AnalyticsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if leads.isEmpty && proposals.isEmpty {
                    EmptyStateView(
                        systemImage: "chart.bar.doc.horizontal",
                        title: "Analytics will appear here",
                        message: "Add leads, send quotes, and save follow-ups to build performance insights."
                    ) {
                        NavigationLink(value: AppRoute.addLead) {
                            Label("Add Lead", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.lpBlue)
                    }
                }

                if viewModel.isLoading {
                    LoadingOverlay(title: "Refreshing insights")
                }

                if let error = viewModel.errorMessage {
                    ErrorBanner(message: error)
                }

                if let insights = viewModel.insights {
                    insightsView(insights)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Analytics")
        .task(id: refreshID) {
            await refresh()
        }
        .refreshable {
            await refresh()
        }
    }

    private var refreshID: String {
        "\(leads.count)-\(proposals.count)-\(followUps.count)"
    }

    private func refresh() async {
        await viewModel.refresh(
            leads: leads,
            proposals: proposals,
            followUps: followUps,
            businessType: ProfileResolver.businessType(from: profiles),
            aiService: aiService
        )
    }

    @ViewBuilder
    private func insightsView(_ insights: SalesInsights) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(insights.headline)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .cardStyle()

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricTile(title: "Conversion rate", value: insights.conversionRate.percentFormatted, systemImage: "chart.line.uptrend.xyaxis", tint: .lpBlue)
            MetricTile(title: "Average quote", value: insights.averageQuoteValue.currencyFormatted, systemImage: "sterlingsign.circle", tint: .lpGreen)
            MetricTile(title: "Best service", value: insights.bestPerformingService, systemImage: "star", tint: .orange)
            MetricTile(title: "Pipeline", value: insights.estimatedRevenuePipeline.currencyFormatted, systemImage: "briefcase", tint: .purple)
        }

        AnalyticsChartCard(title: "Lead source performance", subtitle: "Lead volume by source") {
            if insights.sourcePerformance.isEmpty {
                Text("No source data yet.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart(insights.sourcePerformance) { metric in
                    BarMark(
                        x: .value("Source", metric.label),
                        y: .value("Leads", metric.value)
                    )
                    .foregroundStyle(Color.lpBlue.gradient)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }

        AnalyticsChartCard(title: "Follow-up effectiveness", subtitle: "Saved follow-ups per active lead") {
            Chart([
                SalesInsightMetric(label: "Follow-up", value: insights.followUpEffectiveness),
                SalesInsightMetric(label: "Remaining", value: max(0, 1 - insights.followUpEffectiveness))
            ]) { metric in
                SectorMark(
                    angle: .value("Share", metric.value),
                    innerRadius: .ratio(0.58),
                    angularInset: 2
                )
                .foregroundStyle(by: .value("Metric", metric.label))
            }
        }

        VStack(alignment: .leading, spacing: 10) {
            Text("Recommended actions")
                .font(.headline)
            ForEach(insights.recommendations, id: \.self) { recommendation in
                Label(recommendation, systemImage: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .cardStyle()
    }
}

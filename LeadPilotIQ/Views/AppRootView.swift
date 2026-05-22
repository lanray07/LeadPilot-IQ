import SwiftUI

struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
                    .withAppNavigationDestinations()
            }
            .tabItem {
                Label("Dashboard", systemImage: "square.grid.2x2")
            }

            NavigationStack {
                LeadListView()
                    .withAppNavigationDestinations()
            }
            .tabItem {
                Label("Leads", systemImage: "person.2")
            }

            NavigationStack {
                ProposalCenterView()
                    .withAppNavigationDestinations()
            }
            .tabItem {
                Label("Proposals", systemImage: "doc.text")
            }

            NavigationStack {
                AnalyticsDashboardView()
                    .withAppNavigationDestinations()
            }
            .tabItem {
                Label("Analytics", systemImage: "chart.bar.xaxis")
            }

            NavigationStack {
                SettingsView()
                    .withAppNavigationDestinations()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
    }
}

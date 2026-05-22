import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class SubscriptionService {
    static let productIDs = SubscriptionPlan.paidPlans.compactMap(\.productID)

    var products: [Product] = []
    var currentPlan: SubscriptionPlan = .free
    var renewsAt: Date?
    var isLoading = false
    var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    var isActive: Bool {
        currentPlan.isPaid
    }

    func start() {
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                await self?.listenForTransactionUpdates()
            }
        }

        Task {
            await loadProducts()
            await refreshPurchasedProducts()
        }
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: Self.productIDs)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func purchase(_ plan: SubscriptionPlan) async {
        guard let productID = plan.productID else { return }
        guard let product = products.first(where: { $0.id == productID }) else {
            errorMessage = "StoreKit product \(productID) is not available. Check the StoreKit configuration or App Store Connect setup."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshPurchasedProducts()
            case .pending:
                errorMessage = "Purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                errorMessage = "Unknown purchase result."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func product(for plan: SubscriptionPlan) -> Product? {
        guard let productID = plan.productID else { return nil }
        return products.first(where: { $0.id == productID })
    }

    private func listenForTransactionUpdates() async {
        for await update in Transaction.updates {
            do {
                let transaction = try checkVerified(update)
                await transaction.finish()
                await refreshPurchasedProducts()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func refreshPurchasedProducts() async {
        var bestPlan: SubscriptionPlan = .free
        var renewal: Date?

        for await entitlement in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(entitlement),
                  transaction.revocationDate == nil,
                  let plan = SubscriptionPlan.paidPlans.first(where: { $0.productID == transaction.productID }) else {
                continue
            }

            bestPlan = preferredPlan(bestPlan, plan)
            renewal = transaction.expirationDate ?? renewal
        }

        currentPlan = bestPlan
        renewsAt = renewal
    }

    private func preferredPlan(_ lhs: SubscriptionPlan, _ rhs: SubscriptionPlan) -> SubscriptionPlan {
        let priority: [SubscriptionPlan: Int] = [
            .free: 0,
            .proMonthly: 1,
            .proYearly: 2,
            .businessMonthly: 3
        ]
        return (priority[rhs] ?? 0) > (priority[lhs] ?? 0) ? rhs : lhs
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionStoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

private enum SubscriptionStoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        "StoreKit transaction verification failed."
    }
}

import Foundation
import SwiftUI

@MainActor
final class KnowledgeStore: ObservableObject {
    @Published private(set) var packs: [KnowledgePackState]
    @Published var downloadsAllowed = false
    private(set) var inventoryReady = false

    private let provider: KnowledgeProvider
    private var bootstrapTask: Task<Void, Never>?
    private var mutationTasks: [String: Task<Void, Never>] = [:]

    init(
        datasets: [KnowledgeDatasetConfig],
        provider: KnowledgeProvider
    ) {
        packs = datasets.map { KnowledgePackState(config: $0) }
        self.provider = provider
    }

    var readyDatasets: [KnowledgeDatasetConfig] {
        packs.compactMap { pack in
            guard pack.status == .ready || pack.status == .updateAvailable
            else {
                return nil
            }
            return pack.config
        }
    }

    func bootstrap() async {
        if let bootstrapTask {
            await bootstrapTask.value
            return
        }

        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            await bootstrapDatasets()
        }
        bootstrapTask = task
        await task.value
    }

    private func bootstrapDatasets() async {
        var failed = false
        for dataset in packs.map(\.config) {
            do {
                let result = try await provider.reconcile(dataset: dataset)
                applyReconciliation(result, stableId: dataset.stableId)
            } catch {
                failed = true
                updatePack(dataset.stableId) { pack in
                    pack.status = .download
                    pack.errorMessage = userFacingKnowledgeError(error)
                }
            }
        }
        inventoryReady = !failed
    }

    func retryBootstrap() async {
        await bootstrapTask?.value
        guard !inventoryReady else { return }
        bootstrapTask = nil
        await bootstrap()
    }

    func downloadOrUpdate(stableId: String, onInstalled: (() -> Void)? = nil) {
        guard downloadsAllowed,
            mutationTasks[stableId] == nil,
            let index = packs.firstIndex(where: { $0.id == stableId })
        else {
            return
        }
        let dataset = packs[index].config
        updatePack(stableId) { pack in
            pack.isMutating = true
            pack.progressPercent = 0
            pack.progressLabel = "Starting download..."
            pack.errorMessage = nil
        }

        mutationTasks[stableId] = Task { [weak self] in
            guard let self else { return }
            do {
                let result = try await provider.download(dataset: dataset) { [weak self] progress in
                    Task { @MainActor [weak self] in
                        self?.updatePack(stableId) { pack in
                            pack.progressPercent = min(100, max(0, Int(progress.percentage)))
                            pack.progressLabel = progress.label
                        }
                    }
                }
                applyReconciliation(result, stableId: stableId)
                if result.activeIdentity != nil { onInstalled?() }
            } catch {
                if let result = try? await provider.reconcile(dataset: dataset) {
                    applyReconciliation(result, stableId: stableId)
                }
                updatePack(stableId) { pack in
                    pack.errorMessage = userFacingKnowledgeError(error)
                }
            }
            updatePack(stableId) { pack in
                pack.isMutating = false
                pack.progressPercent = nil
                pack.progressLabel = nil
            }
            mutationTasks.removeValue(forKey: stableId)
        }
    }

    func cancel(stableId: String) {
        guard let dataset = packs.first(where: { $0.id == stableId })?.config else {
            return
        }
        let ownerTask = mutationTasks[stableId]
        Task { [weak self] in
            guard let self else { return }
            let result = await provider.cancel(dataset: dataset)
            await ownerTask?.value
            guard mutationTasks[stableId] == nil else {
                return
            }
            if let result {
                applyReconciliation(result, stableId: stableId)
            }
            updatePack(stableId) { pack in
                pack.isMutating = false
                pack.progressPercent = nil
                pack.progressLabel = nil
            }
        }
    }

    private func applyReconciliation(
        _ result: KnowledgeReconciliation,
        stableId: String
    ) {
        updatePack(stableId) { pack in
            pack.status = result.status
            pack.activeIdentity = result.activeIdentity
            pack.errorMessage = nil
        }
    }

    private func updatePack(
        _ stableId: String,
        update: (inout KnowledgePackState) -> Void
    ) {
        guard let index = packs.firstIndex(where: { $0.id == stableId }) else {
            return
        }
        var updated = packs
        update(&updated[index])
        packs = updated
    }

    private func userFacingKnowledgeError(_ error: Error) -> String {
        switch error {
        case AssetDownloadError.Cancelled:
            return "Download cancelled"
        case AssetDownloadError.StorageFull:
            return "Not enough storage space to download this knowledge pack."
        case AssetDownloadError.Network:
            return "Couldn't download the knowledge pack. Check your connection and try again."
        case AssetDownloadError.Http:
            return "The knowledge pack is currently unavailable. Please try again later."
        case AssetDownloadError.Validation,
            AssetDownloadError.InvalidDownload:
            return "The knowledge pack couldn't be verified. Please try again."
        case AssetDownloadError.Io:
            return "Couldn't save the knowledge pack. Please try again."
        default:
            return "Knowledge pack setup failed. Please try again."
        }
    }
}

struct KnowledgePackState: Identifiable, Sendable {
    var id: String { config.stableId }
    let config: KnowledgeDatasetConfig
    var status: KnowledgeReconciliationStatus?
    var activeIdentity: String?
    var isMutating = false
    var progressPercent: Int?
    var progressLabel: String?
    var errorMessage: String?
}

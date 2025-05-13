import Combine
import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGASwift

@MainActor
@objc final class ItemCollectionViewCellViewModel: NSObject {
    
    @Published private(set) var isSensitive: Bool = false
    @Published private(set) var thumbnail: UIImage?
    
    let node: NodeEntity
    let isVideo: Bool
    let hasThumbnail: Bool
    
    private let sensitiveNodeUseCase: any SensitiveNodeUseCaseProtocol
    private let thumbnailUseCase: any ThumbnailUseCaseProtocol
    private let nodeIconUseCase: any NodeIconUsecaseProtocol
    private let remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol
    private var task: Task<Void, Never>?
    
    init(node: NodeEntity,
         sensitiveNodeUseCase: some SensitiveNodeUseCaseProtocol,
         thumbnailUseCase: some ThumbnailUseCaseProtocol,
         nodeIconUseCase: some NodeIconUsecaseProtocol,
         remoteFeatureFlagUseCase: any RemoteFeatureFlagUseCaseProtocol = DIContainer.remoteFeatureFlagUseCase) {
        
        self.node = node
        self.hasThumbnail = node.hasThumbnail
        self.isVideo = node.name.fileExtensionGroup.isVideo
        self.sensitiveNodeUseCase = sensitiveNodeUseCase
        self.thumbnailUseCase = thumbnailUseCase
        self.nodeIconUseCase = nodeIconUseCase
        self.remoteFeatureFlagUseCase = remoteFeatureFlagUseCase
    }
    
    deinit {
        task?.cancel()
        task = nil
    }
    
    @discardableResult
    func configureCell() -> Task<Void, Never> {
        if let task {
            return task
        } else {
            let task = Task { [weak self] in
                guard let self else { return }
                await applySensitiveConfiguration()
                await loadThumbnail()
            }
            self.task = task
            return task
        }
    }
    
    private nonisolated func loadThumbnail() async {
        guard !Task.isCancelled else { return }
        guard hasThumbnail else {
            await setThumbnailImage(UIImage(data: nodeIconUseCase.iconData(for: node)))
            return
        }
        
        do {
            let thumbnailEntity: ThumbnailEntity
            if let cached = thumbnailUseCase.cachedThumbnail(for: node, type: .thumbnail) {
                thumbnailEntity = cached
            } else {
                await setThumbnailImage(UIImage(data: nodeIconUseCase.iconData(for: node)))
                thumbnailEntity = try await thumbnailUseCase.loadThumbnail(for: node, type: .thumbnail)
            }
            
            let imagePath = thumbnailEntity.url.path()
            await setThumbnailImage(UIImage(contentsOfFile: imagePath))
        } catch {
            MEGALogError("[\(type(of: self))] Error loading thumbnail: \(error)")
        }
    }
    
    private nonisolated func applySensitiveConfiguration() async {
        guard remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .hiddenNodes),
              sensitiveNodeUseCase.isAccessible() else {
            await setIsSensitive(false)
            return
        }
        
        guard !node.isMarkedSensitive else {
            await setIsSensitive(true)
            return
        }
        
        do {
            await setIsSensitive(try sensitiveNodeUseCase.isInheritingSensitivity(node: node))
        } catch {
            MEGALogError("Error checking if node is inheriting sensitivity: \(error)")
        }
    }
    
    private func setIsSensitive(_ newValue: Bool) async {
        isSensitive = newValue
    }
    
    private func setThumbnailImage(_ newImage: UIImage?) async {
        guard !Task.isCancelled else { return }
        thumbnail = newImage
    }
}

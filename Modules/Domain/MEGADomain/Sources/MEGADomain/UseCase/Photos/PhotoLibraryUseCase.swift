import AsyncAlgorithms
import Combine
import MEGASwift

public protocol PhotoLibraryUseCaseProtocol: Sendable {
    /// Load CameraUpload and MediaUpload node
    /// - Returns: PhotoLibraryContainerEntity, which contains CameraUpload and MediaUpload node itself
    func photoLibraryContainer() async -> PhotoLibraryContainerEntity
    
    ///  Load media nodes filtering the results based on the filter options which provide location and mediaType information
    /// - Parameters:
    ///   - filterOptions: PhotosFilterOptionsEntity containing location and mediaTypes to load
    ///   - excludeSensitive: Optional Boolean indicator to exclude sensitiveNodes.If value is not set, it will default to using users account level setting for excluding hidden nodes.
    ///   - searchText: string for media name as search keyword.
    ///   - sortOrder: Returns the resulting nodes in the order marked in this argument.
    /// - Returns: List of media NodeEntities based on the criteria in the parameters provided.
    /// - Important: requesting media with different filter type can defeat the purpose of sortOrder (e.g, filter options `allMedia, or [ .videos, .photos ]` contains photos and videos and `sortOrder` argument become invalid). At the moment, client needs to do sort itself. See `PhotoLibraryContentView` to do local sorting.
    func media(for filterOptions: PhotosFilterOptionsEntity, excludeSensitive: Bool?, searchText: String, sortOrder: SortOrderEntity) async throws -> [NodeEntity]
}

extension PhotoLibraryUseCaseProtocol {
    public func media(for filterOptions: PhotosFilterOptionsEntity, excludeSensitive: Bool? = nil, searchText: String = "", sortOrder: SortOrderEntity = .defaultDesc) async throws -> [NodeEntity] {
        try await self.media(for: filterOptions, excludeSensitive: excludeSensitive, searchText: searchText, sortOrder: sortOrder)
    }
}

public struct PhotoLibraryUseCase<T: PhotoLibraryRepositoryProtocol, U: FilesSearchRepositoryProtocol, V: ContentConsumptionUserAttributeUseCaseProtocol>: PhotoLibraryUseCaseProtocol {
    private let photosRepository: T
    private let searchRepository: U
    private let contentConsumptionUserAttributeUseCase: V
    private let hiddenNodesFeatureFlagEnabled: @Sendable () -> Bool
    
    public init(photosRepository: T, searchRepository: U, contentConsumptionUserAttributeUseCase: V, hiddenNodesFeatureFlagEnabled: @escaping @Sendable () -> Bool) {
        self.photosRepository = photosRepository
        self.searchRepository = searchRepository
        self.contentConsumptionUserAttributeUseCase = contentConsumptionUserAttributeUseCase
        self.hiddenNodesFeatureFlagEnabled = hiddenNodesFeatureFlagEnabled
    }
    
    public func photoLibraryContainer() async -> PhotoLibraryContainerEntity {
        async let cameraUploadNode = try? await photosRepository.photoSourceNode(for: .camera)
        async let mediaUploadNode = try? await photosRepository.photoSourceNode(for: .media)
        
        return await PhotoLibraryContainerEntity(
            cameraUploadNode: cameraUploadNode,
            mediaUploadNode: mediaUploadNode
        )
    }

    public func media(for filterOptions: PhotosFilterOptionsEntity, excludeSensitive: Bool? = nil, searchText: String, sortOrder: SortOrderEntity) async throws -> [NodeEntity] {
        
        let shouldExcludeSensitive = await shouldExcludeSensitive(override: excludeSensitive)
  
        return if filterOptions.isSuperset(of: .allLocations) {
            try await loadAllPhotos(recursive: true, excludeSensitive: shouldExcludeSensitive, includedFormats: filterOptions.requestedNodeFormats, searchText: searchText, sortOrder: sortOrder)
        } else if filterOptions.contains(.cloudDrive) {
            try await mediaFromCloudDriveOnly(excludeSensitive: shouldExcludeSensitive, includedFormats: filterOptions.requestedNodeFormats, searchText: searchText, sortOrder: sortOrder)
        } else if filterOptions.contains(.cameraUploads) {
            try await mediaFromCameraUpload(excludeSensitive: shouldExcludeSensitive, includedFormats: filterOptions.requestedNodeFormats, searchText: searchText, sortOrder: sortOrder)
        } else {
            []
        }
    }
    
    private func shouldExcludeSensitive(override: Bool? = nil) async -> Bool {
        guard hiddenNodesFeatureFlagEnabled() else {
            return false
        }
        
        guard let override else {
            return await !contentConsumptionUserAttributeUseCase.fetchSensitiveAttribute().showHiddenNodes
        }
        return override
    }
    
    private func mediaFromCloudDriveOnly(excludeSensitive: Bool, includedFormats: [NodeFormatEntity], searchText: String, sortOrder: SortOrderEntity) async throws -> [NodeEntity] {
        let container = await photoLibraryContainer()
        let exclusionHandles = [container.cameraUploadNode, container.mediaUploadNode]
            .compactMap(\.?.handle)
        
        return try await loadAllPhotos(recursive: true, excludeSensitive: excludeSensitive, includedFormats: includedFormats, searchText: searchText, sortOrder: sortOrder)
            .filter { exclusionHandles.notContains($0.parentHandle) }
    }
    
    private func mediaFromCameraUpload(excludeSensitive: Bool, includedFormats: [NodeFormatEntity], searchText: String, sortOrder: SortOrderEntity) async throws -> [NodeEntity] {
        
        let container = await photoLibraryContainer()
        
        var nodes: [NodeEntity] = []
        if let cameraUploadNode = container.cameraUploadNode,
           let photosCameraUpload = try? await loadAllPhotos(parentNode: cameraUploadNode, recursive: false, excludeSensitive: excludeSensitive, includedFormats: includedFormats, searchText: searchText, sortOrder: sortOrder) {
            nodes.append(contentsOf: photosCameraUpload)
        }
        
        if let mediaUploadNode = container.mediaUploadNode,
           let photosMediaUpload = try? await loadAllPhotos(parentNode: mediaUploadNode, recursive: false, excludeSensitive: excludeSensitive, includedFormats: includedFormats, searchText: searchText, sortOrder: sortOrder) {
            nodes.append(contentsOf: photosMediaUpload)
        }
        
        return nodes
    }
    
    // MARK: - Private
    private func loadAllPhotos(parentNode: NodeEntity? = nil, recursive: Bool, excludeSensitive: Bool, includedFormats: [NodeFormatEntity], searchText: String, sortOrder: SortOrderEntity) async throws -> [NodeEntity] {
        await includedFormats
            .async
            .compactMap { format -> [NodeEntity]? in
                try? await searchRepository.search(filter: .init(
                    searchText: searchText,
                    parentNode: parentNode,
                    recursive: recursive,
                    supportCancel: false,
                    sortOrderType: sortOrder,
                    formatType: format,
                    excludeSensitive: excludeSensitive))
            }
            .reduce([NodeEntity]()) { $0 + $1 }
    }
}

private extension PhotosFilterOptionsEntity {
    var requestedNodeFormats: [NodeFormatEntity] {
        if isSuperset(of: .allMedia) {
            [.photo, .video]
        } else if contains(.images) {
            [.photo]
        } else if contains(.videos) {
            [.video]
        } else {
            []
        }
    }
}

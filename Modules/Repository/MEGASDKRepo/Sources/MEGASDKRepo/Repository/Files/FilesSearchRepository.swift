import Combine
import MEGADomain
import MEGASdk
import MEGASwift

public final class FilesSearchRepository: NSObject, FilesSearchRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: FilesSearchRepository {
        FilesSearchRepository(sdk: MEGASdk.sharedSdk)
    }
    
    public let nodeUpdatesPublisher: AnyPublisher<[NodeEntity], Never>
    
    private let updater: PassthroughSubject<[NodeEntity], Never>
    private let sdk: MEGASdk
    private var callback: (([NodeEntity]) -> Void)?
    
    private lazy var searchOperationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.qualityOfService = .userInitiated
        return operationQueue
    }()
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
        
        updater = PassthroughSubject<[NodeEntity], Never>()
        nodeUpdatesPublisher = AnyPublisher(updater)
    }
    
    // MARK: - FilesSearchRepositoryProtocol
    
    public func startMonitoringNodesUpdate(callback: (([NodeEntity]) -> Void)?) {
        self.callback = callback
        sdk.add(self)
    }
    
    public func stopMonitoringNodesUpdate() {
        sdk.remove(self)
    }
    
    public func search(filter: SearchFilterEntity, completion: @escaping ([NodeEntity]?, Bool) -> Void) {
        search(filter: filter) { result in
            switch result {
            case .success(let nodes):
                completion(nodes, false)
            case .failure:
                completion(nil, true)
            }
        }
    }
    
    public func search(filter: SearchFilterEntity) async throws -> [NodeEntity] {
        let cancelToken = MEGACancelToken()
        return try await withTaskCancellationHandler<[NodeEntity]> {
            try await withAsyncThrowingValue { completion in
                search(filter: filter, cancelToken: cancelToken) { completion($0) }
            }
        } onCancel: {
            if !cancelToken.isCancelled {
                cancelToken.cancel()
            }
        }
    }
    
    public func search(filter: SearchFilterEntity) async throws -> NodeListEntity {
        let cancelToken = MEGACancelToken()
        return try await withTaskCancellationHandler<NodeListEntity> {
            try await withAsyncThrowingValue { completion in
                search(filter: filter, cancelToken: cancelToken) { completion($0) }
            }
        } onCancel: {
            if !cancelToken.isCancelled {
                cancelToken.cancel()
            }
        }
    }
        
    public func node(by handle: HandleEntity) async -> NodeEntity? {
        sdk.node(forHandle: handle)?.toNodeEntity()
    }
    
    public func cancelSearch() {
        guard searchOperationQueue.operationCount > 0 else { return }
        
        searchOperationQueue.cancelAllOperations()
    }
    
    private func search(filter: SearchFilterEntity, cancelToken: MEGACancelToken, completion: @escaping (Result<NodeListEntity, any Error>) -> Void) {
                        
        let searchOperation = SearchWithFilterOperation(
            sdk: sdk,
            filter: filter.toMEGASearchFilter(),
            recursive: filter.recursive,
            sortOrder: filter.sortOrderType.toMEGASortOrderType(),
            cancelToken: cancelToken,
            completion: { nodeList, isCanceled in
                guard !isCanceled else {
                    completion(.failure(NodeSearchResultErrorEntity.cancelled))
                    return
                }
                
                guard let nodeList else {
                    completion(.failure(NodeSearchResultErrorEntity.noDataAvailable))
                    return
                }
                completion(.success(nodeList.toNodeListEntity()))
            })
        
        searchOperationQueue.addOperation(searchOperation)
    }
    
    private func search(filter: SearchFilterEntity, cancelToken: MEGACancelToken = MEGACancelToken(), completion: @escaping (Result<[NodeEntity], any Error>) -> Void) {
        search(filter: filter, cancelToken: cancelToken) { result in
            completion(result.map { $0.toNodeEntities() })
        }
    }
}

extension FilesSearchRepository: MEGAGlobalDelegate {
    public func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let callback else {
            updater.send(nodeList?.toNodeEntities() ?? [])
            return
        }
        
        callback(nodeList?.toNodeEntities() ?? [])
    }
}

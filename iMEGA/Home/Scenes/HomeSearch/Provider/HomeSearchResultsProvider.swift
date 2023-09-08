import MEGADomain
import MEGAL10n
import MEGASwift
import Search

/// abstraction into a search results 
final class HomeSearchResultsProvider: SearchResultsProviding {
    private let searchFileUseCase: any SearchFileUseCaseProtocol
    private let nodeDetailUseCase: any NodeDetailUseCaseProtocol
    private let nodeRepository: any NodeRepositoryProtocol
    
    init(
        searchFileUseCase: some SearchFileUseCaseProtocol,
        nodeDetailUseCase: some NodeDetailUseCaseProtocol,
        nodeRepository: some NodeRepositoryProtocol
    ) {
        self.searchFileUseCase = searchFileUseCase
        self.nodeDetailUseCase = nodeDetailUseCase
        self.nodeRepository = nodeRepository
    }
    
    func search(queryRequest: SearchQuery) async throws -> SearchResultsEntity {
        // the requirement is to return children/contents of the
        // folder being searched when query is empty, no chips etc
        
        switch queryRequest {
        case .initial:
            return await childrenOfRoot()
        case .userSupplied(let query):
            if shouldShowRoot(for: query) {
                return await childrenOfRoot()
            } else {
                return try await fullSearch(with: query)
            }
        }
    }
    
    private func shouldShowRoot(for queryRequest: SearchQueryEntity) -> Bool {
        if queryRequest == .initialRootQuery {
            return true
        }
        if queryRequest.query == "" && queryRequest.chips == [] {
            return true
        }
        return false
    }
    
    @MainActor
    func childrenOfRoot() async -> SearchResultsEntity {
        guard let root = nodeRepository.rootNode() else {
            return .empty
        }
        let children = await nodeRepository.children(of: root)
        return .init(
            results: children.map { self.mapNodeToSearchResult($0) },
            availableChips: SearchChipEntity.allChips,
            appliedChips: []
        )
    }
    
    func fullSearch(with queryRequest: SearchQueryEntity) async throws -> SearchResultsEntity {
        // SDK does not support empty query and MEGANodeFormatType.unknown
        assert(!(queryRequest.query == "" && queryRequest.chips == []))
        return try await withAsyncThrowingValue(in: { completion in
            searchFileUseCase.searchFiles(
                withName: queryRequest.query,
                nodeFormat: nodeFormatFrom(chip: queryRequest.chips.first),
                searchPath: .root,
                completion: { result in
                    completion(
                        .success(
                            .init(
                                results: result.map { self.mapNodeToSearchResult($0) },
                                // will implement that in FM-797
                                availableChips: SearchChipEntity.allChips,
                                appliedChips: self.chipsFor(query: queryRequest)
                            )
                        )
                    )
                }
            )
        })
    }
    
    private func chipsFor(query: SearchQueryEntity) -> [SearchChipEntity] {
        SearchChipEntity.allChips.filter {
            query.chips.contains($0)
        }
    }
    
    private func nodeFormatFrom(chip: SearchChipEntity?) -> MEGANodeFormatType {
        guard let chip else {
            return .unknown
        }
        let found = SearchChipEntity.allChips.first {
            $0.id == chip.id
        }
        
        guard
            let found,
            let formatType = MEGANodeFormatType(rawValue: found.id)
        else {
            return .unknown
        }
        
        return formatType
    }
    
    private func mapNodeToSearchResult(_ node: NodeEntity) -> SearchResult {
        return .init(
            id: node.handle,
            title: node.name,
            description: nodeDetailUseCase.ownerFolder(of: node.handle)?.name ?? "",
            // We will fill this later on when we do FM-793
            properties: [],
            thumbnailImageData: { await self.loadThumbnail(for: node.handle) },
            type: .node
        )
    }
    
    private func loadThumbnail(for handle: HandleEntity) async -> Data {
        return await withAsyncValue(in: { completion in
            nodeDetailUseCase.loadThumbnail(
                of: handle,
                completion: { image in
                    completion(.success(image?.pngData() ?? Data()))
                }
            )
        })
    }
}

extension SearchChipEntity {
    public static let images = SearchChipEntity(
        id: ChipId(MEGANodeFormatType.photo.rawValue),
        title: Strings.Localizable.Home.Search.Filter.images,
        icon: nil
    )
    public static let docs = SearchChipEntity(
        id: ChipId(MEGANodeFormatType.document.rawValue),
        title: Strings.Localizable.Home.Search.Filter.docs,
        icon: nil
    )
    public static let audio = SearchChipEntity(
        id: ChipId(MEGANodeFormatType.audio.rawValue),
        title: Strings.Localizable.Home.Search.Filter.audio,
        icon: nil
    )
    public static let video = SearchChipEntity(
        id: ChipId(MEGANodeFormatType.video.rawValue),
        title: Strings.Localizable.Home.Search.Filter.video,
        icon: nil
    )
    
    public static var allChips: [Self] {
        [
            .images,
            .docs,
            .audio,
            .video
        ]
    }
}

extension SearchQueryEntity {
    
    /// this checks if we are doing initial search query (or empty search query ) and should results contents of the home folder
    public var isRootDefaultPreviewRequest: Bool {
        self == .initialRootQuery
    }
    /// default search query performed on the appear of the screen results screen
    public static var initialRootQuery: Self {
        SearchQueryEntity(query: "", sorting: .automatic, mode: .home, chips: [])
    }
}

extension SearchResultsEntity {
    /// used as results return when no root folder of the account is found
    ///  we try to get root folder when performing initial or empty search query
    public static var empty: Self {
        .init(results: [], availableChips: [], appliedChips: [])
    }
}
import Foundation

public protocol NodeDataRepositoryProtocol: RepositoryProtocol {
    func nodeAccessLevel(nodeHandle: HandleEntity) -> NodeAccessTypeEntity
    func nodeAccessLevelAsync(nodeHandle: HandleEntity) async -> NodeAccessTypeEntity
    func labelString(label: NodeLabelTypeEntity) -> String
    func getFilesAndFolders(nodeHandle: HandleEntity) -> (childFileCount: Int, childFolderCount: Int)
    func sizeForNode(handle: HandleEntity) -> UInt64?
    func folderInfo(node: NodeEntity) async throws -> FolderInfoEntity?
    func creationDateForNode(handle: HandleEntity) -> Date?
    func nodeForHandle(_ handle: HandleEntity) -> NodeEntity?
    func parentForHandle(_ handle: HandleEntity) -> NodeEntity?
}

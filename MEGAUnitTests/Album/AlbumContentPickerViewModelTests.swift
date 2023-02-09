import XCTest
import Combine
import MEGADomain
import MEGADomainMock
@testable import MEGA

@MainActor
final class AlbumContentPickerViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    
    func testOnDone_whenNoImagesSelected_shouldDismissTheScreen() async {
        let sut = makeAlbumContentPickerViewModel()
        await sut.photosLoadingTask?.value
        sut.onDone()
        XCTAssertTrue(sut.isDismiss)
    }
    
    func testOnDone_whenSomeImagesSelected_shouldDismissTheScreenAndReturnTheAlbumAndPluralSuccessMsg() async {
        let exp = XCTestExpectation(description: "Adding content to album should be successful")
        
        let resultEntity = AlbumElementsResultEntity(success: 2, failure: 0)
        let sut = makeAlbumContentPickerViewModel(resultEntity: resultEntity, completion: { msg, album in
            XCTAssertEqual(msg, "Added 2 items to “\(album.name)”")
            XCTAssertNotNil(album)
            exp.fulfill()
        })
        await sut.photosLoadingTask?.value
        
        let node1 = NodeEntity(name: "a.png", handle: HandleEntity(1))
        let node2 = NodeEntity(name: "b.png", handle: HandleEntity(2))
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([node1, node2])
        sut.onDone()
        await sut.photosLoadingTask?.value
        XCTAssertTrue(sut.isDismiss)
        wait(for: [exp], timeout: 2.0)
    }
    
    func testOnDone_whenOneImageSelected_shouldDismissTheScreenAndReturnTheAlbumAndSingularSuccessMsg() async {
        let exp = XCTestExpectation(description: "Adding content to album should be successful")
        
        let resultEntity = AlbumElementsResultEntity(success: 1, failure: 0)
        let sut = makeAlbumContentPickerViewModel(resultEntity: resultEntity, completion: { msg, album in
            XCTAssertEqual(msg, "Added 1 item to “\(album.name)”")
            XCTAssertNotNil(album)
            exp.fulfill()
        })
        await sut.photosLoadingTask?.value
        
        let node1 = NodeEntity(name: "a.png", handle: HandleEntity(1))
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([node1])
        sut.onDone()
        await sut.photosLoadingTask?.value
        XCTAssertTrue(sut.isDismiss)
        wait(for: [exp], timeout: 2.0)
    }
    
    func testOnCancel_dismissSetToTrue() {
        let viewModel = makeAlbumContentPickerViewModel()
        XCTAssertFalse(viewModel.isDismiss)
        viewModel.onCancel()
        XCTAssertTrue(viewModel.isDismiss)
    }
    
    func testLoadPhotos_initLoadPhotos_shouldUpdateContentLibraryAndSortToNewest() async throws {
        let photos = try makeSamplePhotoNodes()
        let sut = makeAlbumContentPickerViewModel(allPhotos: photos)
        await sut.photosLoadingTask?.value
        let expectedPhotos = photos.filter { $0.hasThumbnail }
            .toPhotoLibrary(withSortType: .newest)
            .allPhotos
        XCTAssertEqual(sut.photoLibraryContentViewModel.library.allPhotos, expectedPhotos)
    }
    
    func testNavigationTitle_whenAddedContent_shouldReturnThreeDifferentResults() {
        let sut = makeAlbumContentPickerViewModel()
        let node1 = NodeEntity(name: "a.png", handle: HandleEntity(1))
        let node2 = NodeEntity(name: "b.png", handle: HandleEntity(2))
        
        let normalNavTitle = "Add items to “Custom Name”"
        XCTAssertEqual(sut.navigationTitle, normalNavTitle)
        
        let exp = expectation(description: "title updates when selection changes")
        exp.expectedFulfillmentCount = 3
        
        var result = [String]()
        sut.$navigationTitle
            .dropFirst(2)
            .sink {
                result.append($0)
                exp.fulfill()
            }.store(in: &subscriptions)
        
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([node1])
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([node1, node2])
        sut.photoLibraryContentViewModel.selection.setSelectedPhotos([])
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(result, [
            "1 item selected",
            "2 items selected",
            normalNavTitle
        ])
    }
    
    func testOnFilter_shouldSetShowFilter() {
        let sut = makeAlbumContentPickerViewModel()
        XCTAssertFalse(sut.photoLibraryContentViewModel.showFilter)
        sut.onFilter()
        XCTAssertTrue(sut.photoLibraryContentViewModel.showFilter)
    }
    
    func testContentLocation_onFilterUpdate_changes() {
        let sut = makeAlbumContentPickerViewModel()
        XCTAssertEqual(sut.photoSourceLocation, .allLocations)
        let exp = expectation(description: "content location updates when filter updates")
        exp.expectedFulfillmentCount = 2
        var result = [PhotosFilterLocation]()
        sut.$photoSourceLocation
            .dropFirst()
            .sink {
                result.append($0)
                exp.fulfill()
            }
            .store(in: &subscriptions)
        
        sut.photoLibraryContentViewModel.filterViewModel.appliedFilterLocation = .cameraUploads
        sut.photoLibraryContentViewModel.filterViewModel.appliedFilterLocation = .cloudDrive
        
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(result, [.cameraUploads, .cloudDrive])
    }
    
    func testContentLibrary_onContentLocationCloudDrive_shouldDisplaySortedCloudDrivePhotos() async throws {
        let photos = try makeSamplePhotoNodes()
        let sut = makeAlbumContentPickerViewModel(allPhotosFromCloudDriveOnly: photos)
        await sut.photosLoadingTask?.value
        XCTAssertTrue(sut.photoLibraryContentViewModel.library.allPhotos.isEmpty)
        
        sut.photoSourceLocation = .cloudDrive
        await sut.photosLoadingTask?.value
        
        let expectedPhotos = photos.filter { $0.hasThumbnail }
            .toPhotoLibrary(withSortType: .newest)
            .allPhotos
        XCTAssertEqual(sut.photoLibraryContentViewModel.library.allPhotos, expectedPhotos)
    }
    
    func testContentLibrary_onContentCameraUpload_shouldDisplaySortedCameraUploadPhotos() async throws {
        let photos = try makeSamplePhotoNodes()
        let sut = makeAlbumContentPickerViewModel(allPhotosFromCameraUpload: photos)
        await sut.photosLoadingTask?.value
        XCTAssertTrue(sut.photoLibraryContentViewModel.library.allPhotos.isEmpty)
        
        sut.photoSourceLocation = .cameraUploads
        await sut.photosLoadingTask?.value
        
        let expectedPhotos = photos.filter { $0.hasThumbnail }
            .toPhotoLibrary(withSortType: .newest)
            .allPhotos
        XCTAssertEqual(sut.photoLibraryContentViewModel.library.allPhotos, expectedPhotos)
    }
    
    private func makeAlbumContentPickerViewModel(resultEntity: AlbumElementsResultEntity? = nil,
                                               allPhotos: [NodeEntity] = [],
                                               allPhotosFromCloudDriveOnly: [NodeEntity] = [],
                                               allPhotosFromCameraUpload: [NodeEntity] = [],
                                               completion: @escaping ((String, AlbumEntity) -> Void) = {_, _ in }) -> AlbumContentPickerViewModel {
        let album = AlbumEntity(id: 4, name: "Custom Name", coverNode: NodeEntity(handle: 4), count: 0, type: .user)
        return AlbumContentPickerViewModel(album: album,
                                           photoLibraryUseCase:
                                            MockPhotoLibraryUseCase(
                                                allPhotos: allPhotos,
                                                allPhotosFromCloudDriveOnly: allPhotosFromCloudDriveOnly,
                                                allPhotosFromCameraUpload: allPhotosFromCameraUpload),
                                           mediaUseCase: MockMediaUseCase(isStringImage: true),
                                           albumContentModificationUseCase: MockAlbumContentModificationUseCase(resultEntity: resultEntity),
                                           completion: completion )
    }
    
    private func makeSamplePhotoNodes() throws -> [NodeEntity] {
        let node1 = NodeEntity(nodeType: .file, name: "TestImage1.png", handle:1, parentHandle: 1, hasThumbnail: true, modificationTime: try "2022-08-18T22:01:04Z".date)
        let node2 = NodeEntity(nodeType: .file, name: "TestImage2.png", handle:2, parentHandle: 1, hasThumbnail: true, modificationTime: try "2022-08-18T22:02:04Z".date)
        let node3 = NodeEntity(nodeType: .file, name: "TestImage3.png", handle:3, parentHandle: 1, hasThumbnail: false, modificationTime: try "2022-08-18T22:03:04Z".date)
        let node4 = NodeEntity(nodeType: .file, name: "TestImage4.png", handle:4, parentHandle: 1, hasThumbnail: true, modificationTime: try "2022-08-18T22:04:04Z".date)
        let node5 = NodeEntity(nodeType: .file, name: "TestVideo.mp4", handle:5, parentHandle: 1, hasThumbnail: true, modificationTime: try "2022-08-18T22:05:04Z".date)
        
        return [node1, node2, node3, node4, node5]
    }
}

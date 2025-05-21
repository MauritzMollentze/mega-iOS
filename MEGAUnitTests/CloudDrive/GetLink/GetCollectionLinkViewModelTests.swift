@testable import MEGA
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAAssets
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGATest
import XCTest

final class GetCollectionLinkViewModelTests: XCTestCase {
    
    @MainActor
    func testNumberOfSections_init_isCorrect() {
        let album = SetEntity(handle: 1, setType: .album)
        let sections = [
            GetLinkSectionViewModel(sectionType: .info, cellViewModels: [], setIdentifier: album.setIdentifier)
        ]
        
        let sut = makeGetCollectionLinkViewModel(setEntity: album,
                                            sectionViewModels: sections)
        XCTAssertEqual(sut.numberOfSections, sections.count)
    }
    
    @MainActor
    func testNumberRowsInSection_init_isCorrect() {
        let album = SetEntity(handle: 1, setType: .album)
        let cellViewModels = [GetLinkStringCellViewModel(link: "Test link")]
        let sections = [
            GetLinkSectionViewModel(sectionType: .info,
                                    cellViewModels: cellViewModels,
                                    setIdentifier: album.setIdentifier)
        ]
        
        let sut = makeGetCollectionLinkViewModel(setEntity: album,
                                            sectionViewModels: sections)
        
        XCTAssertEqual(sut.numberOfRowsInSection(0),
                       cellViewModels.count)
    }
    
    @MainActor
    func testCellViewModel_init_forIndexPath_isCorrect() {
        let album = SetEntity(handle: 1, setType: .album)
        let cellViewModels = [GetLinkStringCellViewModel(link: "Test link")]
        let sections = [
            GetLinkSectionViewModel(sectionType: .info,
                                    cellViewModels: cellViewModels,
                                    setIdentifier: album.setIdentifier)
        ]
        let sut = makeGetCollectionLinkViewModel(setEntity: album,
                                            sectionViewModels: sections)
        let indexPath = IndexPath(row: 0, section: 0)
        XCTAssertEqual(sut.cellViewModel(indexPath: indexPath)?.type,
                       cellViewModels[indexPath.row].type
        )
    }
    
    @MainActor
    func testCellViewModel_init_sectionTypeRetrievalIsCorrect() {
        let album = SetEntity(handle: 1, setType: .album)
        let section = GetLinkSectionViewModel(sectionType: .info,
                                              cellViewModels: [],
                                              setIdentifier: album.setIdentifier)
        let sut = makeGetCollectionLinkViewModel(setEntity: album,
                                            sectionViewModels: [section])
        XCTAssertEqual(sut.sectionType(forSection: 0),
                       section.sectionType)
    }
    
    @MainActor func testDispatchViewConfiguration_onNoExportedAlbums_shouldSetTitleToShareLinkAndTrackScreen() {
        for hiddenNodesFeatureFlagActive in [true, false] {
            let album = SetEntity(handle: 1, setType: .album, isExported: false)
            let tracker = MockTracker()
            let sut = makeGetCollectionLinkViewModel(setEntity: album,
                                                shareCollectionUseCase: MockShareCollectionUseCase(doesCollectionsContainSensitiveElement: [album.handle: false]),
                                                tracker: tracker,
                                                hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            
            let expectedTitle = Strings.Localizable.General.MenuAction.ShareLink.title(1)
            test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
                .configureView(title: expectedTitle,
                               isMultilink: false,
                               shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)),
                .showHud(.status(Strings.Localizable.generatingLinks)),
                .dismissHud
            ], expectationValidation: ==)
            
            assertTrackAnalyticsEventCalled(
                trackedEventIdentifiers: tracker.trackedEventIdentifiers,
                with: [
                    SingleAlbumLinkScreenEvent()
                ]
            )
        }
    }
    
    @MainActor func testDispatchViewConfiguration_onExportedAlbums_shouldSetTitleToManageShareLink() {
        for hiddenNodesFeatureFlagActive in [true, false] {
            
            let album = SetEntity(handle: 1, setType: .album, isExported: true)
            let sut = makeGetCollectionLinkViewModel(setEntity: album,
                                                hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)

            let expectedTitle = Strings.Localizable.General.MenuAction.ManageLink.title(1)
            test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
                .configureView(title: expectedTitle,
                               isMultilink: false,
                               shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)),
                .showHud(.status(Strings.Localizable.generatingLinks)),
                .dismissHud
            ], expectationValidation: ==)
        }
    }
    
    @MainActor
    func testDispatchOnViewReady_onAlbumLinkLoaded_shouldUpdateLinkSectionLinkCell() async throws {
        for hiddenNodesFeatureFlagActive in [true, false] {
            
            let album = SetEntity(handle: 1, setType: .album)
            let sections = [
                GetLinkSectionViewModel(sectionType: .link,
                                        cellViewModels: [GetLinkStringCellViewModel(link: "")],
                                        setIdentifier: album.setIdentifier)
            ]
            let link = "the shared link"
            let shareCollectionUseCase = MockShareCollectionUseCase(
                shareCollectionLinkResult: .success(link),
                doesCollectionsContainSensitiveElement: [album.handle: false])

            let sut = makeGetCollectionLinkViewModel(setEntity: album,
                                                shareCollectionUseCase: shareCollectionUseCase,
                                                sectionViewModels: sections,
                                                hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            
            let updatedIndexPath = IndexPath(row: 0, section: 0)
            await test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
                .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                               isMultilink: false,
                               shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)),
                .showHud(.status(Strings.Localizable.generatingLinks)),
                .enableLinkActions,
                .reloadRows([updatedIndexPath]),
                .dismissHud
            ], expectationValidation: ==)
            
            await sut.loadingTask?.value
            
            let updatedCell = try XCTUnwrap(sut.cellViewModel(indexPath: updatedIndexPath) as? GetLinkStringCellViewModel)
            await test(viewModel: updatedCell, action: .onViewReady, expectedCommands: [
                .configView(title: link, leftImage: MEGAAssets.UIImage.linkGetLink, isRightImageViewHidden: true)
            ])
        }
    }
    
    @MainActor
    func testDispatchSwitchToggled_onDecryptKeySeparateToggled_linkAndKeyShouldUpdateCorrectly() async throws {
        for hiddenNodesFeatureFlagActive in [true, false] {
            let album = SetEntity(handle: 1, setType: .album)
            let sections = [
                GetLinkSectionViewModel(sectionType: .decryptKeySeparate,
                                        cellViewModels: [GetLinkSwitchOptionCellViewModel(type: .decryptKeySeparate,
                                                                                          configuration: GetLinkSwitchCellViewConfiguration(title: "Test"))],
                                        setIdentifier: album.setIdentifier),
                GetLinkSectionViewModel(sectionType: .link,
                                        cellViewModels: [GetLinkStringCellViewModel(link: "")],
                                        setIdentifier: album.setIdentifier)
            ]
            let link = "/collection/link#key"
            let shareCollectionUseCase = MockShareCollectionUseCase(shareCollectionLinkResult: .success(link),
                                                          doesCollectionsContainSensitiveElement: [album.handle: false])
            let sut = makeGetCollectionLinkViewModel(setEntity: album,
                                                shareCollectionUseCase: shareCollectionUseCase,
                                                sectionViewModels: sections,
                                                hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            await test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
                .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                               isMultilink: false,
                               shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)
                              ),
                .showHud(.status(Strings.Localizable.generatingLinks)),
                .enableLinkActions,
                .reloadRows([IndexPath(row: 0, section: 1)]),
                .dismissHud
            ], expectationValidation: ==)
            
            await sut.loadingTask?.value
            
            let decryptToggleIndexPath = IndexPath(row: 0, section: 0)
            let expectedKeySectionIndex = 2
            test(viewModel: sut, action: .switchToggled(indexPath: decryptToggleIndexPath, isOn: true),
                 expectedCommands: [
                    .insertSections([expectedKeySectionIndex]),
                    .reloadSections([1]),
                    .configureToolbar(isDecryptionKeySeperate: true)
                 ],
                 expectationValidation: ==)
            let decryptCellViewModel = try XCTUnwrap(sut.cellViewModel(indexPath: decryptToggleIndexPath) as?  GetLinkSwitchOptionCellViewModel)
            XCTAssertTrue(decryptCellViewModel.isSwitchOn)
            test(viewModel: sut, action: .switchToggled(indexPath: decryptToggleIndexPath, isOn: false),
                 expectedCommands: [
                    .reloadSections([1]),
                    .deleteSections([expectedKeySectionIndex]),
                    .configureToolbar(isDecryptionKeySeperate: false)
                 ],
                 expectationValidation: ==)
        }
    }
    
    @MainActor
    func testDispatchShareLink_onDecryptSeperateOff_shouldOnlyShareOriginalLink() async {
        for hiddenNodesFeatureFlagActive in [true, false] {
            
            let album = SetEntity(handle: 1, setType: .album)
            let link = "https://mega.nz/collection/link#key"
            let sections = [
                GetLinkSectionViewModel(sectionType: .decryptKeySeparate,
                                        cellViewModels: [GetLinkSwitchOptionCellViewModel(type: .decryptKeySeparate,
                                                                                          configuration: GetLinkSwitchCellViewConfiguration(title: "Test"))],
                                        setIdentifier: album.setIdentifier)
            ]
            let shareCollectionUseCase = MockShareCollectionUseCase(shareCollectionLinkResult: .success(link),
                                                          doesCollectionsContainSensitiveElement: [album.handle: false])
            let sut = makeGetCollectionLinkViewModel(setEntity: album,
                                                shareCollectionUseCase: shareCollectionUseCase,
                                                sectionViewModels: sections,
                                                hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            
            await test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
                .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                               isMultilink: false,
                               shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)
                              ),
                .showHud(.status(Strings.Localizable.generatingLinks)),
                .dismissHud
            ], expectationValidation: ==)
            
            await sut.loadingTask?.value
            let barButton = UIBarButtonItem()
            test(viewModel: sut, action: .shareLink(sender: barButton),
                 expectedCommands: [
                    .showShareActivity(sender: barButton, link: link, key: nil)
                 ],
                 expectationValidation: ==)
        }
    }
    
    @MainActor
    func testDispatchShareLink_onDecryptSeperateOn_shouldShareLinkSeperatelyFromKey() async {
        for hiddenNodesFeatureFlagActive in [true, false] {
            let album = SetEntity(handle: 1, setType: .album)
            let linkOnly = "https://mega.nz/collection/link"
            let key = "key"
            let link = "\(linkOnly)#\(key)"
            let sections = [
                GetLinkSectionViewModel(sectionType: .decryptKeySeparate,
                                        cellViewModels: [GetLinkSwitchOptionCellViewModel(type: .decryptKeySeparate,
                                                                                          configuration: GetLinkSwitchCellViewConfiguration(title: "Test", isSwitchOn: true))],
                                        setIdentifier: album.setIdentifier)
            ]
            let shareCollectionUseCase = MockShareCollectionUseCase(shareCollectionLinkResult: .success(link),
                                                          doesCollectionsContainSensitiveElement: [album.handle: false])
            let sut = makeGetCollectionLinkViewModel(setEntity: album,
                                                shareCollectionUseCase: shareCollectionUseCase,
                                                sectionViewModels: sections,
                                                hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            
            await test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
                .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                               isMultilink: false,
                               shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)
                              ),
                .showHud(.status(Strings.Localizable.generatingLinks)),
                .dismissHud
            ], expectationValidation: ==)
            await sut.loadingTask?.value
            let barButton = UIBarButtonItem()
            test(viewModel: sut, action: .shareLink(sender: barButton),
                 expectedCommands: [
                    .showShareActivity(sender: barButton, link: linkOnly, key: key)
                 ],
                 expectationValidation: ==)
        }
    }
    
    @MainActor
    func testDispatchCopyLink_onDecryptSeperateOff_shouldCopyShareOriginalLink() async {
        for hiddenNodesFeatureFlagActive in [true, false] {
            let album = SetEntity(handle: 1, setType: .album)
            let link = "https://mega.nz/collection/link#key"
            let sections = [
                GetLinkSectionViewModel(sectionType: .decryptKeySeparate,
                                        cellViewModels: [GetLinkSwitchOptionCellViewModel(type: .decryptKeySeparate,
                                                                                          configuration: GetLinkSwitchCellViewConfiguration(title: "Test"))],
                                        setIdentifier: album.setIdentifier)
            ]
            let shareCollectionUseCase = MockShareCollectionUseCase(shareCollectionLinkResult: .success(link),
                                                          doesCollectionsContainSensitiveElement: [album.handle: false])

            let sut = makeGetCollectionLinkViewModel(setEntity: album,
                                                shareCollectionUseCase: shareCollectionUseCase,
                                                sectionViewModels: sections,
                                                hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            
            await test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
                .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                               isMultilink: false,
                               shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)
                              ),
                .showHud(.status(Strings.Localizable.generatingLinks)),
                .dismissHud
            ], expectationValidation: ==)
            
            await sut.loadingTask?.value
            
            test(viewModel: sut,
                 action: .copyLink,
                 expectedCommands: [
                    .addToPasteBoard(link),
                    .showHud(.custom(MEGAAssets.UIImage.copy,
                                     Strings.Localizable.SharedItems.GetLink.linkCopied(1)))
                 ],
                 expectationValidation: ==)
        }
    }
    
    @MainActor
    func testDispatchCopyLink_onDecryptSeperateOn_shouldCopyOnlyLink() async {
        for hiddenNodesFeatureFlagActive in [true, false] {
            let album = SetEntity(handle: 1, setType: .album)
            let linkOnly = "https://mega.nz/collection/link"
            let key = "key"
            let link = "\(linkOnly)#\(key)"
            let sections = [
                GetLinkSectionViewModel(sectionType: .decryptKeySeparate,
                                        cellViewModels: [GetLinkSwitchOptionCellViewModel(type: .decryptKeySeparate,
                                                                                          configuration: GetLinkSwitchCellViewConfiguration(title: "Test", isSwitchOn: true))],
                                        setIdentifier: album.setIdentifier)
            ]
            let shareCollectionUseCase = MockShareCollectionUseCase(shareCollectionLinkResult: .success(link),
                                                          doesCollectionsContainSensitiveElement: [album.handle: false])

            let sut = makeGetCollectionLinkViewModel(setEntity: album,
                                                shareCollectionUseCase: shareCollectionUseCase,
                                                sectionViewModels: sections,
                                                hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            
            await test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear],
                 expectedCommands: [
                    .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                                   isMultilink: false,
                                   shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)
                                  ),
                    .showHud(.status(Strings.Localizable.generatingLinks)),
                    .dismissHud
                 ],
                 expectationValidation: ==)
            
            await sut.loadingTask?.value
            
            test(viewModel: sut, action: .copyLink,
                 expectedCommands: [
                    .addToPasteBoard(linkOnly),
                    .showHud(.custom(MEGAAssets.UIImage.copy,
                                     Strings.Localizable.SharedItems.GetLink.linkCopied(1)))
                 ],
                 expectationValidation: ==)
        }
    }
    
    @MainActor
    func testDispatchCopyKey_onDecryptSeperateOn_shouldCopyKey() async {
        for hiddenNodesFeatureFlagActive in [true, false] {
            let album = SetEntity(handle: 1, setType: .album)
            let linkOnly = "https://mega.nz/collection/link"
            let key = "key"
            let link = "\(linkOnly)#\(key)"
            let sections = [
                GetLinkSectionViewModel(sectionType: .decryptKeySeparate,
                                        cellViewModels: [GetLinkSwitchOptionCellViewModel(type: .decryptKeySeparate,
                                                                                          configuration: GetLinkSwitchCellViewConfiguration(title: "Test", isSwitchOn: true))],
                                        setIdentifier: album.setIdentifier)
            ]
            let shareCollectionUseCase = MockShareCollectionUseCase(shareCollectionLinkResult: .success(link),
                                                          doesCollectionsContainSensitiveElement: [album.handle: false])

            let sut = makeGetCollectionLinkViewModel(setEntity: album,
                                                shareCollectionUseCase: shareCollectionUseCase,
                                                sectionViewModels: sections,
                                                hiddenNodesFeatureFlagActive: hiddenNodesFeatureFlagActive)
            
            await test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
                .configureView(title: Strings.Localizable.General.MenuAction.ShareLink.title(1),
                               isMultilink: false,
                               shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)
                              ),
                .showHud(.status(Strings.Localizable.generatingLinks)),
                .dismissHud
            ], expectationValidation: ==)
            
            await sut.loadingTask?.value
            
            test(viewModel: sut, action: .copyKey,
                 expectedCommands: [
                    .addToPasteBoard(key),
                    .showHud(.custom(MEGAAssets.UIImage.copy,
                                     Strings.Localizable.keyCopiedToClipboard))
                 ], expectationValidation: ==)
        }
    }
    
    @MainActor func testDispatchViewConfiguration_onNotExportedAlbumsAndContainsSensitiveElement_shouldPromptAlert() {
        
        let album = SetEntity(handle: 1, setType: .album, isExported: false)
        let sut = makeGetCollectionLinkViewModel(setEntity: album,
                                            shareCollectionUseCase: MockShareCollectionUseCase(doesCollectionsContainSensitiveElement: [album.handle: true]),
                                            hiddenNodesFeatureFlagActive: true)
        
        let expectedTitle = Strings.Localizable.General.MenuAction.ShareLink.title(1)
        test(viewModel: sut, actions: [.onViewReady, .onViewDidAppear], expectedCommands: [
            .configureView(title: expectedTitle,
                           isMultilink: false,
                           shareButtonTitle: Strings.Localizable.General.MenuAction.ShareLink.title(1)),
            .showHud(.status(Strings.Localizable.generatingLinks)),
            .dismissHud,
            .showAlert(AlertModel(
                title: Strings.Localizable.CameraUploads.Albums.AlbumLink.Sensitive.Alert.title,
                message: Strings.Localizable.CameraUploads.Albums.AlbumLink.Sensitive.Alert.Message.single,
                actions: [
                    .init(title: Strings.Localizable.cancel, style: .cancel, handler: { }),
                    .init(title: Strings.Localizable.continue, style: .default, isPreferredAction: true, handler: { })
                ]))
        ], expectationValidation: ==)
    }
    
    @MainActor
    func testDispatch_onViewReadyAndAlbumContainsSensitiveElementAndContinuesAndTapsContinue_shouldLoadLinks() throws {
        let album = SetEntity(handle: 1, setType: .album)
        let sections = [
            GetLinkSectionViewModel(sectionType: .link, cellViewModels: [
                GetLinkStringCellViewModel(link: "")
            ], setIdentifier: album.setIdentifier)
        ]
        let expectedRowReloads = sections.indices.map { IndexPath(row: 0, section: $0) }
        let tracker = MockTracker()
        let sut = makeGetCollectionLinkViewModel(
            setEntity: album,
            shareCollectionUseCase: MockShareCollectionUseCase(
                shareCollectionLinkResult: .success("link-\(album.handle)"),
                doesCollectionsContainSensitiveElement: [album.handle: true]),
            sectionViewModels: sections,
            tracker: tracker,
            hiddenNodesFeatureFlagActive: true)
        
        let expectation = expectation(description: "Expect sensitive content alert to appear")
        var continueAction: AlertModel.AlertAction?
        sut.invokeCommand = {
            if case let .showAlert(alertModel) = $0,
               let action = alertModel.actions.first(where: { $0.title ==  Strings.Localizable.continue }) {
                continueAction = action
                expectation.fulfill()
            }
        }
        
        sut.dispatch(.onViewDidAppear)
        
        wait(for: [expectation], timeout: 1)
        
        test(viewModel: sut, trigger: { continueAction?.handler() }, expectedCommands: [
            .showHud(.status(Strings.Localizable.generatingLinks)),
            .enableLinkActions,
            .reloadRows(expectedRowReloads),
            .dismissHud
        ], expectationValidation: ==)
    }
    
    @MainActor
    func testDispatch_onViewReadyAndAlbumContainsSensitiveElementAndContinuesAndTapsCancel_shouldDismissView() throws {
        let album = SetEntity(handle: 1, setType: .album)
        let tracker = MockTracker()
        let sut = makeGetCollectionLinkViewModel(
            setEntity: album,
            shareCollectionUseCase: MockShareCollectionUseCase(
                doesCollectionsContainSensitiveElement: [album.handle: true]),
            tracker: tracker,
            hiddenNodesFeatureFlagActive: true)
        
        let expectation = expectation(description: "Expect sensitive content alert to appear")
        var cancelAction: AlertModel.AlertAction?
        sut.invokeCommand = {
            if case let .showAlert(alertModel) = $0,
               let action = alertModel.actions.first(where: { $0.title ==  Strings.Localizable.cancel }) {
                cancelAction = action
                expectation.fulfill()
            }
        }
        
        sut.dispatch(.onViewDidAppear)
        
        wait(for: [expectation], timeout: 1)
        
        test(viewModel: sut, trigger: { cancelAction?.handler() }, expectedCommands: [
            .dismiss
        ], expectationValidation: ==)
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func makeGetCollectionLinkViewModel(
        setEntity: SetEntity,
        shareCollectionUseCase: some ShareCollectionUseCaseProtocol = MockShareCollectionUseCase(),
        sectionViewModels: [GetLinkSectionViewModel] = [],
        tracker: some AnalyticsTracking = MockTracker(),
        hiddenNodesFeatureFlagActive: Bool = true
    ) -> GetCollectionLinkViewModel {
        GetCollectionLinkViewModel(setEntity: setEntity,
                              shareCollectionUseCase: shareCollectionUseCase,
                              sectionViewModels: sectionViewModels,
                              tracker: tracker,
                              remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(list: [.hiddenNodes: hiddenNodesFeatureFlagActive]))
    }
}

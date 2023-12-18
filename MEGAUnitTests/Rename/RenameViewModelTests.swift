import DeviceCenter
@testable import MEGA
import MEGADomainMock
import MEGAL10n
import XCTest

class RenameViewModelTests: XCTestCase {
    func testRename_deviceRenamedSuccessfully() async {
        let (viewModel, router, _) = makeSUT(renameShouldThrowError: false)
        let newName = "NewDeviceName"
        
        await viewModel.rename(newName)
        
        XCTAssertTrue(router.didFinishSuccessfullyCalled)
    }
    
    func testRename_deviceRenamedWithError() async {
        let (viewModel, router, _) = makeSUT(renameShouldThrowError: true)
        let newName = "NewDeviceName"
        
        await viewModel.rename(newName)
        
        XCTAssertTrue(router.didFinishWithErrorCalled)
    }
    
    func testRename_deviceRenamedSuccessfullyAndThenWithError() async {
        let (viewModel, router, useCase) = makeSUT(renameShouldThrowError: false)
        let newName = "NewDeviceName"
        
        await viewModel.rename(newName)
        XCTAssertTrue(router.didFinishSuccessfullyCalled)
        
        useCase.shouldThrowError = true
        
        await viewModel.rename(newName)
        XCTAssertTrue(router.didFinishWithErrorCalled)
    }
    
    func testIsDuplicated_duplicatedName_returnsTrue() {
        let deviceName = "DeviceName"
        let (viewModel, _, _) = makeSUT(otherDeviceNames: [deviceName], renameShouldThrowError: false)
        
        let result = viewModel.isDuplicated(deviceName)
        
        XCTAssertTrue(result)
    }
    
    func testIsDuplicated_nonDuplicatedName_returnsFalse() {
        let deviceName = "DeviceName"
        let (viewModel, _, _) = makeSUT(otherDeviceNames: ["OtherDeviceName"], renameShouldThrowError: false)
        
        let result = viewModel.isDuplicated(deviceName)
        
        XCTAssertFalse(result)
    }
    
    func testContainsInvalidChars_containsInvalidChars_returnsTrue() {
        let invalidText = "***************"
        let (viewModel, _, _) = makeSUT(renameShouldThrowError: false)
        
        let result = viewModel.containsInvalidChars(invalidText)
        
        XCTAssertTrue(result)
    }
    
    func testContainsInvalidChars_noInvalidChars_returnsFalse() {
        let validText = "ValidName"
        let (viewModel, _, _) = makeSUT(renameShouldThrowError: false)
        
        let result = viewModel.containsInvalidChars(validText)
        
        XCTAssertFalse(result)
    }
    
    func testTextfieldText_returnsDeviceOldName() {
        let oldName = "OldDeviceName"
        let (viewModel, _, _) =  makeSUT(deviceOldName: oldName, renameShouldThrowError: false)
        
        let result = viewModel.textfieldText()
        
        XCTAssertEqual(result, oldName)
    }
    
    func testTextfieldPlaceHolder_returnsCorrectPlaceholder() {
        let (viewModel, _, _) =  makeSUT(renameShouldThrowError: false)
        
        let result = viewModel.textfieldPlaceHolder()
        
        XCTAssertEqual(result, Strings.Localizable.Device.Center.Rename.Device.title)
    }
    
    func testAlertTitle_isDuplicated_returnsDuplicatedTitle() {
        let duplicatedText = "DuplicateName"
        let (viewModel, _, _) = makeSUT(otherDeviceNames: [duplicatedText], renameShouldThrowError: false)
        
        let result = viewModel.alertTitle(text: duplicatedText)
        
        XCTAssertEqual(result, Strings.Localizable.Device.Center.Rename.Device.Duplicated.name)
    }
    
    func testAlertTitle_defaultCase_returnsRenameTitle() {
        let validText = "ValidName"
        let (viewModel, _, _) =  makeSUT(renameShouldThrowError: false)
        
        let result = viewModel.alertTitle(text: validText)
        
        XCTAssertEqual(result, Strings.Localizable.rename)
    }
    
    func testAlertMessage_isDuplicated_returnsDuplicatedMessage() {
        let duplicatedText = "DuplicateName"
        let (viewModel, _, _) = makeSUT(otherDeviceNames: [duplicatedText], renameShouldThrowError: false)
        
        let result = viewModel.alertMessage(text: duplicatedText)
        
        XCTAssertEqual(result, Strings.Localizable.Device.Center.Rename.Device.Different.name)
    }
    
    func testAlertMessage_defaultCase_returnsDefaultMessage() {
        let validText = "ValidName"
        let (viewModel, _, _) = makeSUT(renameShouldThrowError: false)
        
        let result = viewModel.alertMessage(text: validText)
        
        XCTAssertEqual(result, Strings.Localizable.renameNodeMessage)
    }
    
    func testAlertTextsColor_containsInvalidChars_returnsRedColor() {
        let invalidText = ":<>?"
        let (viewModel, _, _) = makeSUT(renameShouldThrowError: false)
        
        let result = viewModel.alertTextsColor(text: invalidText)
        
        XCTAssertEqual(result, MEGAAppColor.Red._FF3B30.uiColor)
    }
    
    func testAlertTextsColor_isDuplicated_returnsRedColor() {
        let duplicatedText = "DuplicateName"
        let (viewModel, _, _) = makeSUT(otherDeviceNames: [duplicatedText], renameShouldThrowError: false)
        
        let result = viewModel.alertTextsColor(text: duplicatedText)
        
        XCTAssertEqual(result, MEGAAppColor.Red._FF3B30.uiColor)
    }
    
    func testAlertTextsColor_defaultCase_returnsLabelColor() {
        let validText = "ValidText"
        let (viewModel, _, _) = makeSUT(renameShouldThrowError: false)
        
        let result = viewModel.alertTextsColor(text: validText)
        
        XCTAssertEqual(result, .label)
    }
    
    func testAlertTestsColor_deviceNameLargerThanAllowed_returnsRedColor() {
        let invalidName = "12345678901234567890123456789012345"
        let (viewModel, _, _) = makeSUT(renameShouldThrowError: false)
        
        let result = viewModel.alertTextsColor(text: invalidName)
        
        XCTAssertEqual(result, MEGAAppColor.Red._FF3B30.uiColor)
    }
    
    func testIsActionButtonEnabled_textIsEmpty_returnsFalse() {
        let emptyText = ""
        let (viewModel, _, _) = makeSUT(renameShouldThrowError: false)
        
        let result = viewModel.isActionButtonEnabled(text: emptyText)
        
        XCTAssertFalse(result)
    }
    
    func testIsActionButtonEnabled_containsInvalidChars_returnsFalse() {
        let invalidText = "|*/"
        let (viewModel, _, _) = makeSUT(renameShouldThrowError: false)
        
        let result = viewModel.isActionButtonEnabled(text: invalidText)
        
        XCTAssertFalse(result)
    }
    
    func testIsActionButtonEnabled_isDuplicated_returnsFalse() {
        let duplicatedText = "DuplicateName"
        let (viewModel, _, _) = makeSUT(otherDeviceNames: [duplicatedText], renameShouldThrowError: false)
        
        let result = viewModel.isActionButtonEnabled(text: duplicatedText)
        
        XCTAssertFalse(result)
    }
    
    func testIsActionButtonEnabled_defaultCase_returnsTrue() {
        let validText = "ValidText"
        let (viewModel, _, _) = makeSUT(renameShouldThrowError: false)
        
        let result = viewModel.isActionButtonEnabled(text: validText)
        
        XCTAssertTrue(result)
    }
    
    func testIsActionButtonEnabled_deviceNameLargerThanAllowed_returnsFalse() {
        let invalidName = "12345678901234567890123456789012345"
        let (viewModel, _, _) = makeSUT(renameShouldThrowError: false)
        
        let result = viewModel.isActionButtonEnabled(text: invalidName)
        
        XCTAssertFalse(result)
    }
    
    private func makeSUT(
        deviceId: String = "device1",
        deviceOldName: String = "OldName",
        otherDeviceNames: [String] = [],
        renameShouldThrowError: Bool,
        maxDeviceNameCharacters: Int = 32,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (RenameViewModel, MockRenameViewRouter, MockRenameUseCase) {
        let renameEntity = RenameActionEntity(
            deviceId: deviceId,
            deviceOldName: deviceOldName,
            maxCharacters: maxDeviceNameCharacters,
            otherDeviceNames: otherDeviceNames) {
                
            }
        let router = MockRenameViewRouter()
        let renameUseCase = MockRenameUseCase(shouldThrowError: renameShouldThrowError)
        let viewModel = RenameViewModel(
            router: router,
            type: .device(renameEntity: renameEntity),
            renameUseCase: renameUseCase
        )
        
        return (viewModel, router, renameUseCase)
    }
}

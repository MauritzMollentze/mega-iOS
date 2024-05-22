import Foundation
import XCTest

public extension XCTestCase {
    
    func makeImageURL(systemImageName: String = "folder") throws -> URL {
        let localImage = try XCTUnwrap(UIImage(systemName: systemImageName))
        let localURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: false)
        let isLocalFileCreated = FileManager.default.createFile(atPath: localURL.path, contents: localImage.pngData())
        XCTAssertTrue(isLocalFileCreated)
        
        addTeardownBlock {
            let path = if #available(iOS 16.0, *) {
                localURL.path()
            } else {
                localURL.path
            }
            try FileManager.default.removeItem(atPath: path)
        }
        
        return localURL
    }
}

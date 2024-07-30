import AVKit
import Photos
import UIKit

extension PHAccessLevel {
    // app requests read/write access
    static let MEGAAccessLevel: PHAccessLevel = .readWrite
}

public struct DevicePermissionsHandler {
    
    public init(
        mediaAccessor: @escaping (AVMediaType) async -> Bool,
        mediaStatusAccessor: @escaping (AVMediaType) -> AVAuthorizationStatus,
        photoAccessor: @escaping (PHAccessLevel) async -> PHAuthorizationStatus,
        photoStatusAccessor: @escaping (PHAccessLevel) -> PHAuthorizationStatus,
        notificationsAccessor: @escaping () async -> Bool,
        notificationsStatusAccessor: @escaping () async -> UNAuthorizationStatus
    ) {
        self.mediaAccessor = mediaAccessor
        self.mediaStatusAccessor = mediaStatusAccessor
        self.photoAccessor = photoAccessor
        self.photoStatusAccessor = photoStatusAccessor
        self.notificationsAccessor = notificationsAccessor
        self.notificationsStatusAccessor = notificationsStatusAccessor
    }
    
    private let mediaAccessor: (AVMediaType) async -> Bool
    private let mediaStatusAccessor: (AVMediaType) -> AVAuthorizationStatus
    
    private let photoAccessor: (PHAccessLevel) async -> PHAuthorizationStatus
    private let photoStatusAccessor: (PHAccessLevel) -> PHAuthorizationStatus
    
    private let notificationsAccessor: () async -> Bool
    private let notificationsStatusAccessor: () async -> UNAuthorizationStatus
    
}

public extension DevicePermissionsHandler {
    static func makeHandler() -> Self {
        .init(
            mediaAccessor: { await AVCaptureDevice.requestAccess(for: $0) },
            mediaStatusAccessor: { AVCaptureDevice.authorizationStatus(for: $0) },
            photoAccessor: { await PHPhotoLibrary.requestAuthorization(for: $0) },
            photoStatusAccessor: { PHPhotoLibrary.authorizationStatus(for: $0) },
            notificationsAccessor: {
                do {
                    return try await UNUserNotificationCenter.current().requestAuthorization(options: notificationOptions)
                } catch {
                    return false
                }
            },
            notificationsStatusAccessor: {
                await withUnsafeContinuation { continuation in
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        continuation.resume(returning: settings.authorizationStatus)
                    }
                }
            }
        )
    }
    
    static var notificationOptions: UNAuthorizationOptions {
        [.badge, .sound, .alert]
    }
}

extension DevicePermissionsHandler: DevicePermissionsHandling {
    
    public func requestPhotoLibraryAccessPermissions() async -> Bool {
        let level = await photoAccessor(.MEGAAccessLevel)
        return level == .authorized || level == .limited
    }
    
    public func requestPermission(for mediaType: AVMediaType) async -> Bool {
        await mediaAccessor(mediaType)
    }
    
    public func requestNotificationsPermission() async -> Bool {
        await notificationsAccessor()
    }
    
    // readings current status of authorization
    
    public func notificationPermissionStatus() async -> UNAuthorizationStatus {
        await notificationsStatusAccessor()
    }
    
    public var photoLibraryAuthorizationStatus: PHAuthorizationStatus {
        photoStatusAccessor(.MEGAAccessLevel)
    }
    
    public var shouldAskForAudioPermissions: Bool {
        mediaStatusAccessor(.audio) == .notDetermined
    }
    
    public var shouldAskForVideoPermissions: Bool {
        mediaStatusAccessor(.video) == .notDetermined
    }
    
    public var shouldAskForPhotosPermissions: Bool {
        photoLibraryAuthorizationStatus == .notDetermined
    }
    
    public var hasAuthorizedAccessToPhotoAlbum: Bool {
        photoLibraryAuthorizationStatus == .authorized
    }

    public func shouldAskForNotificationPermission() async -> Bool {
        await notificationsStatusAccessor() == .notDetermined
    }
    
    public var isVideoPermissionAuthorized: Bool {
        mediaStatusAccessor(.video) == .authorized
    }
    
    public var audioPermissionAuthorizationStatus: AVAuthorizationStatus {
        mediaStatusAccessor(.audio)
    }
}

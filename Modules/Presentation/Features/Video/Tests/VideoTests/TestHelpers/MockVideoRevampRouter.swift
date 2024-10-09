import MEGADomain
import SwiftUI
import UIKit
import Video

final class MockVideoRevampRouter: VideoRevampRouting {
    
    func openMediaBrowser(for video: NodeEntity, allVideos: [NodeEntity]) { }
    
    func openMoreOptions(for video: NodeEntity, sender: Any) { }
    
    func openVideoPlaylistContent(for videoPlaylistEntity: VideoPlaylistEntity, presentationConfig: VideoPlaylistContentSnackBarPresentationConfig) { }
    
    func openVideoPicker(completion: @escaping ([NodeEntity]) -> Void) { }
    
    func popScreen() { }
    
    func openRecentlyWatchedVideos() { }
    
    func showShareLink(videoPlaylist: VideoPlaylistEntity) -> some View { EmptyView() }
    
    func build() -> UIViewController { UIViewController() }
    
    func start() { }
}
import Foundation

struct L10nRepository: L10nRepositoryProtocol {
    var appLanguage: String {
        LocalizationSystem.sharedLocal()?.getLanguage() ?? "en"
    }
    
    var deviceRegion: String {
        Locale.autoupdatingCurrent.regionCode ?? Locale.autoupdatingCurrent.identifier
    }
}

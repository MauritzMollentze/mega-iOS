import MEGAL10n
import Search

extension SearchChipEntity {
    public static let images = SearchChipEntity(
        id: ChipId(MEGANodeFormatType.photo.rawValue),
        title: Strings.Localizable.Home.Search.Filter.images
    )
    public static let folders = SearchChipEntity(
        id: ChipId.folder,
        title: Strings.Localizable.Home.Search.Filter.folders
    )
    public static let audio = SearchChipEntity(
        id: ChipId(MEGANodeFormatType.audio.rawValue),
        title: Strings.Localizable.Home.Search.Filter.audio
    )
    public static let video = SearchChipEntity(
        id: ChipId(MEGANodeFormatType.video.rawValue),
        title: Strings.Localizable.Home.Search.Filter.video
    )
    public static let pdf = SearchChipEntity(
        id: MEGANodeFormatType.pdf.rawValue,
        title: Strings.Localizable.Home.Search.Filter.pdfs
    )
    public static let docs = SearchChipEntity(
        id: ChipId(MEGANodeFormatType.document.rawValue),
        title: Strings.Localizable.Home.Search.Filter.docs
    )
    public static let presentation = SearchChipEntity(
        id: ChipId(MEGANodeFormatType.presentation.rawValue),
        title: Strings.Localizable.Home.Search.Filter.presentations
    )
    public static let archives = SearchChipEntity(
        id: ChipId(MEGANodeFormatType.archive.rawValue),
        title: Strings.Localizable.Home.Search.Filter.archives
    )
    public static let nodeTypes = SearchChipEntity(
        id: ChipId.nodeType,
        title: Strings.Localizable.Home.Search.ChipsGroup.NodeType.pillTitle,
        subchipsPickerTitle: Strings.Localizable.Home.Search.ChipsGroup.NodeType.pickerTitle,
        subchips: allChips
    )

    // We should include .folders chip also after we migrate SDK to MegaFilter in FM-1403
    public static var allChips: [Self] {
        [
            .images,
            .audio,
            .video,
            .folders,
            .pdf,
            .docs,
// disable Presentations chip until [FM-1403] is finished
//            .presentation, [FM-1427]
            .archives
        ]
    }

    public static var allChipsGrouped: [Self] {
        [
            nodeTypes
        ]
    }

    public static func allChips(areChipsGroupEnabled: Bool) -> [Self] {
        areChipsGroupEnabled ? allChipsGrouped : allChips
    }
}

extension SearchQueryEntity {
    var isFolderChipSelected: Bool {
        chips.first?.id == ChipId.folder
    }
}

// "Special" chipses which don't rely on MEGANodeFormatType to trigger filter based search once tapped on them
private extension ChipId {
    static var folder: Self { -1 }
    static var nodeType: Self { -2 }
}

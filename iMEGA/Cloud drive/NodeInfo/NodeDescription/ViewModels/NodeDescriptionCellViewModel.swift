import Foundation
import MEGASwift

final class NodeDescriptionCellViewModel {
    let textViewEdgeInsets: UIEdgeInsets
    let editingDisabled: Bool
    let placeholderText: String
    let description: () -> NodeDescriptionCellControllerModel.Description?
    let descriptionUpdated: (String) -> Void
    let saveDescription: (String) -> Void
    let isTextViewFocused: (Bool) -> Void
    private let maxCharactersAllowed: Int

    init(
        maxCharactersAllowed: Int,
        editingDisabled: Bool,
        placeholderText: String,
        textViewEdgeInsets: UIEdgeInsets,
        description: @escaping () -> NodeDescriptionCellControllerModel.Description?,
        descriptionUpdated: @escaping (String) -> Void,
        saveDescription: @escaping (String) -> Void,
        isTextViewFocused: @escaping (Bool) -> Void
    ) {
        self.maxCharactersAllowed = maxCharactersAllowed
        self.editingDisabled = editingDisabled
        self.placeholderText = placeholderText
        self.textViewEdgeInsets = textViewEdgeInsets
        self.description = description
        self.descriptionUpdated = descriptionUpdated
        self.saveDescription = saveDescription
        self.isTextViewFocused = isTextViewFocused
    }

    /// Determines if editing should end based on the given text.
    /// - Parameter text: The text being edited.
    /// - Returns: `true` if the text contains only one character and that character is a newline, indicating that editing should end. Otherwise, returns `false`.
    func shouldEndEditing(for text: String) -> Bool {
        text.count == 1 && text.last?.isNewline == true
    }

    func shouldChangeTextIn(
        in range: NSRange,
        currentText: String,
        replacementText: String
    ) -> Bool {
        let newLength = currentText.utf16.count - range.length + replacementText.utf16.count
        guard newLength > maxCharactersAllowed else { return true }
        return false
    }

    func truncateAndReplaceText(
        in targetRange: NSRange,
        of currentText: String,
        with newText: String
    ) -> String? {
        guard let stringRange = Range(targetRange, in: currentText) else { return nil }

        let maxReplaceableLength = maxCharactersAllowed - (currentText.utf16.count - targetRange.length)
        guard maxReplaceableLength > 0,
              let truncatedText = newText.utf16ValidatedTruncation(to: maxReplaceableLength) else {
            return nil
        }

        return currentText.replacingCharacters(in: stringRange, with: truncatedText)
    }
}
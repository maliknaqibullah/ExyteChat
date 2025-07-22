import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct DocumentPicker: UIViewControllerRepresentable {
    var onPicked: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.item]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPicked: ([URL]) -> Void

        init(onPicked: @escaping ([URL]) -> Void) {
            self.onPicked = onPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPicked(urls)
        }
    }
}

//
//  FileThumbnailView.swift
//  Chat
//
//  Created by Malik on 22/07/2025.
//


import SwiftUI
import QuickLookThumbnailing

struct FileThumbnailView: View {
    let fileURL: URL
    @State private var thumbnailImage: UIImage? = nil

    var body: some View {
        Group {
            if let image = thumbnailImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        ProgressView()
                    )
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear {
            generateThumbnail()
        }
    }

    private func generateThumbnail() {
        let size = CGSize(width: 60, height: 60)
        let scale = UIScreen.main.scale
        let request = QLThumbnailGenerator.Request(fileAt: fileURL,
                                                   size: size,
                                                   scale: scale,
                                                   representationTypes: .all)

        QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { thumbnail, error in
            if let image = thumbnail?.uiImage {
                DispatchQueue.main.async {
                    self.thumbnailImage = image
                }
            }
        }
    }
}

//
//  AttachmentSheetView.swift
//  Chat
//
//  Created by Malik on 21/07/2025.
//
import SwiftUI


struct AttachmentSheetView: View {
    let viewModel: InputViewModel
      let onAction: (InputViewAction) -> Void
      @Binding var isPresented: Bool
      let theme: ChatTheme

    
    var options: [AttachmentOption] {
        [
            AttachmentOption(title: "Camera", systemImage: "camera") {
                onAction(.camera)
                isPresented = false   // dismiss the sheet here
            },
            AttachmentOption(title: "Photo", systemImage: "photo") {
                onAction(.photo)
                isPresented = false
            },
            AttachmentOption(title: "Files", systemImage: "folder") {
                onAction(.document)
            },
            AttachmentOption(title: "Location", systemImage: "location") {
                onAction(.location)
            },
            AttachmentOption(title: "Contact", systemImage: "person.crop.circle") {
                print("Contact tapped")
            },
            AttachmentOption(title: "More", systemImage: "ellipsis.circle") {
                print("More tapped")
            }
        ]
    }


    let columns = [
        GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
    ]

    var body: some View {
        ZStack {
            // 🍃 Background with blur material
            VisualEffectBlur(blurStyle: .systemMaterial)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Capsule()
                    .frame(width: 40, height: 5)
                    .foregroundColor(.gray.opacity(0.3))
                    .padding(.top, 8)

                Text("Choose Attachment")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: columns, spacing: 28) {
                    ForEach(options) { option in
                        VStack(spacing: 6) {
                            AnimatedButton(action: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                option.action()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 50, height: 50)

                                    Image(systemName: option.systemImage)
                                        .font(.system(size: 22))
                                        .foregroundColor(theme.colors.sendButtonBackground)
                                }
                            }

                            Text(option.title)
                                .font(.footnote)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 10)
            }
            .padding(.bottom, 20)
        }
    }
}


struct AnimatedButton<Content: View>: View {
    let action: () -> Void
    let content: () -> Content

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            action()
        }) {
            content()
                .scaleEffect(isPressed ? 0.95 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}


struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}


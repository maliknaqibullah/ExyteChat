//
//  InputView.swift
//  Chat
//
//  Created by Alex.M on 25.05.2022.
//

import SwiftUI
import ExyteMediaPicker
import GiphyUISDK
import MapKit


public enum InputViewStyle: Sendable {
    case message
    case signature
}

struct AttachmentOption: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let action: () -> Void
}


public enum InputViewAction: Sendable {
    case giphy
    case photo
    case add
    case camera
    case send

    case recordAudioHold
    case recordAudioTap
    case recordAudioLock
    case stopRecordAudio
    case deleteRecord
    case playRecord
    case pauseRecord
    case location
    case document

    case saveEdit
    case cancelEdit
}

public enum InputViewState: Sendable {
    case empty
    case hasTextOrMedia

    case waitingForRecordingPermission
    case isRecordingHold
    case isRecordingTap
    case hasRecording
    case playingRecording
    case pausedRecording

    case editing

    var canSend: Bool {
        switch self {
        case .hasTextOrMedia, .hasRecording, .isRecordingTap, .playingRecording, .pausedRecording: return true
        default: return false
        }
    }
}

public enum AvailableInputType: Sendable {
    case text
    case media
    case audio
    case giphy
    case location // New
    case document // New
}

public struct InputViewAttachments {
    var medias: [Media] = []
    var recording: Recording?
    var giphyMedia: GPHMedia?
    var replyMessage: ReplyMessage?
    var location: MapLocation? // New
    var documentURL: URL? // New
}

struct InputView: View {
    
    @Environment(\.chatTheme) private var theme
    @Environment(\.mediaPickerTheme) private var pickerTheme

    @EnvironmentObject private var keyboardState: KeyboardState
    
    @ObservedObject var viewModel: InputViewModel
    var inputFieldId: UUID
    var style: InputViewStyle
    var availableInputs: [AvailableInputType]
    var messageStyler: (String) -> AttributedString
    var recorderSettings: RecorderSettings = RecorderSettings()
    var localization: ChatLocalization
    
    @StateObject var recordingPlayer = RecordingPlayer()
    
    private var onAction: (InputViewAction) -> Void {
        viewModel.inputViewAction()
    }
    
    private var state: InputViewState {
        viewModel.state
    }
    
    @State private var showSheet = false
    
    @State private var selectedDocumentURL: URL?
    @State private var annotations: [MapLocation] = []

    
    @State private var overlaySize: CGSize = .zero
    
    @State private var recordButtonFrame: CGRect = .zero
    @State private var lockRecordFrame: CGRect = .zero
    @State private var deleteRecordFrame: CGRect = .zero
    
    @State private var dragStart: Date?
    @State private var tapDelayTimer: Timer?
    @State private var cancelGesture = false
    private let tapDelay = 0.2
    
    var body: some View {
        VStack {
            viewOnTop
            HStack(alignment: .bottom, spacing: 10) {
                HStack(alignment: .bottom, spacing: 0) {
                    leftView
                    middleView
                    rightView
                }
                .background {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(style == .message ? theme.colors.inputBG : theme.colors.inputSignatureBG)
                }
                
                rightOutsideButton
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(backgroundColor)
        .onAppear {
            viewModel.recordingPlayer = recordingPlayer
            viewModel.setRecorderSettings(recorderSettings: recorderSettings)
        }
        .onDrag(towards: .bottom, ofAmount: 100...) {
            keyboardState.resignFirstResponder()
        }
        .sheet(item: $viewModel.activeSheet) { sheet in
                switch sheet {
                case .documentPicker:
                    DocumentPicker { url in
                        selectedDocumentURL = url
                        viewModel.activeSheet = nil
                        print("Selected document: \(url)")
                    }

                case .locationPicker:
                    LocationPicker { coordinate in
                        print("Location picked: \(coordinate)")
                        viewModel.pickedLocation = coordinate
                        annotations = [MapLocation(coordinate: coordinate)]
                        viewModel.activeSheet = nil
                    }

                case .attachmentPicker:
                    AttachmentSheetView(
                        viewModel: viewModel,
                        onAction: onAction,
                        isPresented: Binding(
                            get: { viewModel.activeSheet != nil },
                            set: { if !$0 { viewModel.activeSheet = nil } }
                        ),
                        theme: theme
                    )
                    .presentationDetents([.height(320)])
                    .presentationDragIndicator(.visible)
                }
            
        }


    }
    
    @ViewBuilder
    var leftView: some View {
        if [.isRecordingTap, .isRecordingHold, .hasRecording, .playingRecording, .pausedRecording].contains(state) {
            deleteRecordButton
        } else {
            switch style {
            case .message:
                if isMediaAvailable() {
                    attachButton
                }
                if isGiphyAvailable() {
                    giphyButton
                }
            case .signature:
                if viewModel.mediaPickerMode == .cameraSelection {
                    addButton
                } else {
                    Color.clear.frame(width: 12, height: 1)
                }
            }
        }
    }
    
    
    
    @ViewBuilder
    var middleView: some View {
        Group {
            switch state {
            case .hasRecording, .playingRecording, .pausedRecording:
                recordWaveform
            case .isRecordingHold:
                swipeToCancel
            case .isRecordingTap:
                recordingInProgress
            default:
                TextInputView(
                    text: $viewModel.text,
                    inputFieldId: inputFieldId,
                    style: style,
                    availableInputs: availableInputs,
                    localization: localization
                )
            }
        }
        .frame(minHeight: 48)
    }
    
    @ViewBuilder
    var rightView: some View {
        Group {
            switch state {
            case .empty, .waitingForRecordingPermission:
                if case .message = style, isMediaAvailable() {
                    cameraButton
                }
            case .isRecordingHold, .isRecordingTap:
                recordDurationInProcess
            case .hasRecording:
                recordDuration
            case .playingRecording, .pausedRecording:
                recordDurationLeft
            default:
                Color.clear.frame(width: 8, height: 1)
            }
        }
        .frame(minHeight: 48)
    }
    
    @ViewBuilder
    var editingButtons: some View {
        HStack {
            Button {
                onAction(.cancelEdit)
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
                    .fontWeight(.bold)
                    .padding(5)
                    .background(Circle().foregroundStyle(.red))
            }
            
            Button {
                onAction(.saveEdit)
            } label: {
                Image(systemName: "checkmark")
                    .foregroundStyle(.white)
                    .fontWeight(.bold)
                    .padding(5)
                    .background(Circle().foregroundStyle(.green))
            }
        }
    }
    
    @ViewBuilder
    var rightOutsideButton: some View {
        if state == .editing {
            editingButtons
                .frame(height: 48)
        }
        else {
            ZStack {
                if [.isRecordingTap, .isRecordingHold].contains(state) {
                    RecordIndicator()
                        .viewSize(80)
                        .foregroundColor(theme.colors.sendButtonBackground)
                }
                Group {
                    if state.canSend || !isAudioAvailable()   {
                        sendButton
                            .disabled(!state.canSend)
                    } else {
                        recordButton
                            .highPriorityGesture(dragGesture())
                    }
                }
                .compositingGroup()
                .overlay(alignment: .top) {
                    Group {
                        if state == .isRecordingTap {
                            stopRecordButton
                        } else if state == .isRecordingHold {
                            lockRecordButton
                        }
                    }
                    .sizeGetter($overlaySize)
                    // hardcode 28 for now because sizeGetter returns 0 somehow
                    .offset(y: (state == .isRecordingTap ? -28 : -overlaySize.height) - 24)
                }
            }
            .viewSize(48)
        }
    }
    
    @ViewBuilder
    var viewOnTop: some View {
        if let message = viewModel.attachments.replyMessage {
            VStack(spacing: 8) {
                Rectangle()
                    .foregroundColor(theme.colors.messageFriendBG)
                    .frame(height: 2)
                
                HStack {
                    theme.images.reply.replyToMessage
                    Capsule()
                        .foregroundColor(theme.colors.messageMyBG)
                        .frame(width: 2)
                    VStack(alignment: .leading) {
                        Text(localization.replyToText + " " + message.user.name)
                            .font(.caption2)
                            .foregroundColor(theme.colors.mainCaptionText)
                        if !message.text.isEmpty {
                            textView(message.text)
                                .font(.caption2)
                                .lineLimit(1)
                                .foregroundColor(theme.colors.mainText)
                        }
                    }
                    .padding(.vertical, 2)
                    
                    Spacer()
                    
                    if let first = message.attachments.first {
                        AsyncImageView(url: first.thumbnail, size: CGSize(width: 30, height: 30))
                            .viewSize(30)
                            .cornerRadius(4)
                            .padding(.trailing, 16)
                    }
                    
                    if let _ = message.recording {
                        theme.images.inputView.microphone
                            .renderingMode(.template)
                            .foregroundColor(theme.colors.mainTint)
                    }
                    
                    theme.images.reply.cancelReply
                        .onTapGesture {
                            viewModel.attachments.replyMessage = nil
                        }
                }
                .padding(.horizontal, 26)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    @ViewBuilder
    func textView(_ text: String) -> some View {
        Text(text.styled(using: messageStyler))
    }
    
    var attachButton: some View {
        Button {
//            onAction(.document)
            viewModel.activeSheet = .attachmentPicker

        } label: {
            theme.images.inputView.attach
                .viewSize(24)
                .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 6))
        }
    }
    
    var giphyButton: some View {
        Button {
            onAction(.giphy)
        } label: {
            theme.images.inputView.sticker
                .resizable()
                .viewSize(24)
                .padding(EdgeInsets(top: 12, leading: 6, bottom: 12, trailing: 12))
        }
    }
    
    var addButton: some View {
        Button {
            onAction(.add)
        } label: {
            theme.images.inputView.add
                .viewSize(24)
                .circleBackground(theme.colors.sendButtonBackground)
                .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 8))
        }
    }
    
    var cameraButton: some View {
        Button {
            onAction(.camera)
        } label: {
            theme.images.inputView.attachCamera
                .viewSize(24)
                .padding(EdgeInsets(top: 12, leading: 8, bottom: 12, trailing: 12))
        }
    }
    
    var sendButton: some View {
        Button {
            onAction(.send)
        } label: {
            theme.images.inputView.arrowSend
                .viewSize(48)
                .circleBackground(theme.colors.sendButtonBackground)
        }
    }
    
    var recordButton: some View {
        theme.images.inputView.microphone
            .viewSize(48)
            .circleBackground(theme.colors.sendButtonBackground)
            .frameGetter($recordButtonFrame)
    }
    
    var deleteRecordButton: some View {
        Button {
            onAction(.deleteRecord)
        } label: {
            theme.images.recordAudio.deleteRecord
                .viewSize(24)
                .padding(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 8))
        }
        .frameGetter($deleteRecordFrame)
    }
    
    var stopRecordButton: some View {
        Button {
            onAction(.stopRecordAudio)
        } label: {
            theme.images.recordAudio.stopRecord
                .viewSize(28)
                .background(
                    Capsule()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.4), radius: 1)
                )
        }
    }
    
    var lockRecordButton: some View {
        Button {
            onAction(.recordAudioLock)
        } label: {
            VStack(spacing: 20) {
                theme.images.recordAudio.lockRecord
                theme.images.recordAudio.sendRecord
            }
            .frame(width: 28)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.4), radius: 1)
            )
        }
        .frameGetter($lockRecordFrame)
    }
    
    var swipeToCancel: some View {
        HStack {
            Spacer()
            Button {
                onAction(.deleteRecord)
            } label: {
                HStack {
                    theme.images.recordAudio.cancelRecord
                        .renderingMode(.template)
                        .foregroundStyle(theme.colors.mainText)
                    Text(localization.cancelButtonText)
                        .font(.footnote)
                        .foregroundColor(theme.colors.mainText)
                }
            }
            Spacer()
        }
    }
    
    var recordingInProgress: some View {
        HStack {
            Spacer()
            Text(localization.recordingText)
                .font(.footnote)
                .foregroundColor(theme.colors.mainText)
            Spacer()
        }
    }
    
    var recordDurationInProcess: some View {
        HStack {
            Circle()
                .foregroundColor(theme.colors.recordDot)
                .viewSize(6)
            recordDuration
        }
    }
    
    @ViewBuilder
    var recordDuration: some View {
        if let recording = viewModel.attachments.recording {
            RecordDurationView(recording: recording, theme: theme)
        }
    }
    
    var recordDurationLeft: some View {
        Text(DateFormatter.timeString(Int(recordingPlayer.secondsLeft)))
            .foregroundColor(theme.colors.mainText)
            .opacity(0.6)
            .font(.caption2)
            .monospacedDigit()
            .padding(.trailing, 12)
    }
    
    var playRecordButton: some View {
        Button {
            onAction(.playRecord)
        } label: {
            theme.images.recordAudio.playRecord
        }
    }
    
    var pauseRecordButton: some View {
        Button {
            onAction(.pauseRecord)
        } label: {
            theme.images.recordAudio.pauseRecord
        }
    }
    
    @ViewBuilder
    var recordWaveform: some View {
        if let samples = viewModel.attachments.recording?.waveformSamples {
            HStack(spacing: 8) {
                Group {
                    if state == .hasRecording || state == .pausedRecording {
                        playRecordButton
                    } else if state == .playingRecording {
                        pauseRecordButton
                    }
                }
                .frame(width: 20)
                
                RecordWaveformPlaying(samples: samples, progress: recordingPlayer.progress, color: theme.colors.mainText, addExtraDots: true) { progress in
                    Task {
                        await recordingPlayer.seek(with: viewModel.attachments.recording!, to: progress)
                    }
                }
            }
            .padding(.horizontal, 8)
        }
    }
    
    var backgroundColor: Color {
        switch style {
        case .message:
            return theme.colors.mainBG
        case .signature:
            return pickerTheme.main.pickerBackground
        }
    }

    func dragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0.0, coordinateSpace: .global)
            .onChanged { [state] value in
                if dragStart == nil {
                    dragStart = Date()
                    cancelGesture = false
                    tapDelayTimer = Timer.scheduledTimer(withTimeInterval: tapDelay, repeats: false) { _ in
                        if state != .isRecordingTap, state != .waitingForRecordingPermission {
                            DispatchQueue.main.async {
                                self.onAction(.recordAudioHold)
                            }
                        }
                    }
                }
                
                if value.location.y < lockRecordFrame.minY,
                   value.location.x > recordButtonFrame.minX {
                    cancelGesture = true
                    onAction(.recordAudioLock)
                }
                
                if value.location.x < UIScreen.main.bounds.width/2,
                   value.location.y > recordButtonFrame.minY {
                    cancelGesture = true
                    onAction(.deleteRecord)
                }
            }
            .onEnded() { value in
                if !cancelGesture {
                    tapDelayTimer = nil
                    if recordButtonFrame.contains(value.location) {
                        if let dragStart = dragStart, Date().timeIntervalSince(dragStart) < tapDelay {
                            onAction(.recordAudioTap)
                        } else if state != .waitingForRecordingPermission {
                            onAction(.send)
                        }
                    }
                    else if lockRecordFrame.contains(value.location) {
                        onAction(.recordAudioLock)
                    }
                    else if deleteRecordFrame.contains(value.location) {
                        onAction(.deleteRecord)
                    } else {
                        onAction(.send)
                    }
                }
                dragStart = nil
            }
    }
    
    private func isAudioAvailable() -> Bool {
        return availableInputs.contains(AvailableInputType.audio)
    }
    
    private func isGiphyAvailable() -> Bool {
        return availableInputs.contains(AvailableInputType.giphy)
    }
    
    private func isMediaAvailable() -> Bool {
        return availableInputs.contains(AvailableInputType.media)
    }
}

@MainActor
func performBatchTableUpdates(_ tableView: UITableView, closure: ()->()) async {
    await withCheckedContinuation { continuation in
        tableView.performBatchUpdates {
            closure()
        } completion: { _ in
            continuation.resume()
        }
    }
}

struct RecordDurationView: View {
    @ObservedObject var recording: Recording
    var theme: ChatTheme

    var body: some View {
        Text(DateFormatter.timeString(Int(recording.duration)))
            .foregroundColor(theme.colors.mainText)
            .opacity(0.6)
            .font(.caption2)
            .monospacedDigit()
            .padding(.trailing, 12)
    }
}





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



struct DocumentPicker: UIViewControllerRepresentable {
    var onPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPicked: onPicked)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var onPicked: (URL) -> Void

        init(onPicked: @escaping (URL) -> Void) {
            self.onPicked = onPicked
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPicked(url)
        }
    }
}







struct LocationPicker: View {
    @Environment(\.presentationMode) var presentationMode

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.5553, longitude: 69.2075),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @State private var selectedCoordinate: CLLocationCoordinate2D?

    var onLocationPicked: (CLLocationCoordinate2D) -> Void

    var body: some View {
        VStack {
            Text("Tap the map to pick a location")
                .font(.headline)
                .padding()

            TappableMapView(region: $region, selectedCoordinate: $selectedCoordinate)
                .frame(height: 300)

            Button("Select This Location") {
                let coordinateToSend = selectedCoordinate ?? region.center
                onLocationPicked(coordinateToSend)
                presentationMode.wrappedValue.dismiss()
            }
            .padding()
            .disabled(selectedCoordinate == nil)
        }
    }
}

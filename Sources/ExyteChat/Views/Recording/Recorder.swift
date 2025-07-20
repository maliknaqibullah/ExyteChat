//
//  Recorder.swift
//
//  Created by Alisa Mylnikova on 09.03.2023.
//

import Foundation
@preconcurrency import AVFoundation
import CoreGraphics

final actor Recorder {

    // duration and waveform samples
    typealias ProgressHandler = @Sendable (Double, [CGFloat]) -> Void

    private let audioSession = AVAudioSession()
    private var audioRecorder: AVAudioRecorder?

    private var soundSamples: [CGFloat] = []
    private var recorderSettings = RecorderSettings()

    var isAllowedToRecordAudio: Bool {
        if #available(iOS 17, *) {
            AVAudioApplication.shared.recordPermission == .granted
        } else {
            audioSession.recordPermission == .granted
        }
    }

    var isRecording: Bool {
        audioRecorder?.isRecording ?? false
    }

    func setRecorderSettings(_ recorderSettings: RecorderSettings) {
        self.recorderSettings = recorderSettings
    }

    func startRecording(durationProgressHandler: @escaping ProgressHandler) async -> URL? {
        if !isAllowedToRecordAudio {
            let granted = await audioSession.requestRecordPermission()
            if granted {
                return await startRecordingInternal(durationProgressHandler)
            }
            return nil
        } else {
            return await startRecordingInternal(durationProgressHandler)
        }
    }

    private func startRecordingInternal(_ durationProgressHandler: @escaping ProgressHandler) async -> URL? {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let recordingUrl = FileManager.tempDirPath
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth]
            )
            try AVAudioSession.sharedInstance().setActive(true)

            let recorder = try AVAudioRecorder(url: recordingUrl, settings: settings)
            recorder.isMeteringEnabled = true

            guard recorder.prepareToRecord() else {
                print("Failed to prepare recorder")
                return nil
            }

            guard recorder.record() else {
                print("Failed to start recording")
                return nil
            }

            self.audioRecorder = recorder

            // Start async timer loop
            startTimerLoop(durationProgressHandler)

            return recordingUrl
        } catch {
            print("Recording setup failed: \(error)")
            return nil
        }
    }

    private func startTimerLoop(_ durationProgressHandler: @escaping ProgressHandler) {
        Task { [weak self] in
            while let self, await self.audioRecorder?.isRecording == true {
                await self.onTimer(durationProgressHandler)
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
        }
    }

func onTimer(_ durationProgressHandler: @escaping ProgressHandler) {
    guard let recorder = audioRecorder, recorder.isRecording else {
        return
    }

    recorder.updateMeters()
    let power = recorder.averagePower(forChannel: 0)
    let currentTime = recorder.currentTime

    let normalizedPower = max(0, min(1, (power + 60) / 60))
    soundSamples.append(CGFloat(normalizedPower))

    // ✅ Extract data *inside* actor context
    let snapshotSamples = self.soundSamples

    // ✅ Now safely call handler outside actor context
    DispatchQueue.main.async {
        durationProgressHandler(currentTime, snapshotSamples)
    }
}


    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        // Timer is no longer used, so nothing to invalidate
    }

    private func fileExtension(for formatID: AudioFormatID) -> String? {
        switch formatID {
        case kAudioFormatMPEG4AAC: return ".aac"
        case kAudioFormatLinearPCM: return ".wav"
        case kAudioFormatMPEGLayer3: return ".mp3"
        case kAudioFormatAppleLossless: return ".m4a"
        case kAudioFormatOpus: return ".opus"
        case kAudioFormatAC3: return ".ac3"
        case kAudioFormatFLAC: return ".flac"
        case kAudioFormatAMR: return ".amr"
        case kAudioFormatMIDIStream: return ".midi"
        case kAudioFormatULaw: return ".ulaw"
        case kAudioFormatALaw: return ".alaw"
        case kAudioFormatAMR_WB: return ".awb"
        case kAudioFormatEnhancedAC3: return ".eac3"
        case kAudioFormatiLBC: return ".ilbc"
        default: return nil
        }
    }
}

public struct RecorderSettings: Codable, Hashable {
    var audioFormatID: AudioFormatID
    var sampleRate: CGFloat
    var numberOfChannels: Int
    var encoderBitRateKey: Int
    var linearPCMBitDepth: Int
    var linearPCMIsFloatKey: Bool
    var linearPCMIsBigEndianKey: Bool
    var linearPCMIsNonInterleaved: Bool

    public init(audioFormatID: AudioFormatID = kAudioFormatMPEG4AAC,
                sampleRate: CGFloat = 12000,
                numberOfChannels: Int = 1,
                encoderBitRateKey: Int = 128,
                linearPCMBitDepth: Int = 16,
                linearPCMIsFloatKey: Bool = false,
                linearPCMIsBigEndianKey: Bool = false,
                linearPCMIsNonInterleaved: Bool = false) {
        self.audioFormatID = audioFormatID
        self.sampleRate = sampleRate
        self.numberOfChannels = numberOfChannels
        self.encoderBitRateKey = encoderBitRateKey
        self.linearPCMBitDepth = linearPCMBitDepth
        self.linearPCMIsFloatKey = linearPCMIsFloatKey
        self.linearPCMIsBigEndianKey = linearPCMIsBigEndianKey
        self.linearPCMIsNonInterleaved = linearPCMIsNonInterleaved
    }
}

extension AVAudioSession {
    func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }
}

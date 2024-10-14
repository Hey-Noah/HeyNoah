
// SpeechService.swift
import Foundation
import Speech
import AVFoundation
import Combine
import AVFAudio

class SpeechService: NSObject, SFSpeechRecognizerDelegate, ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var request = SFSpeechAudioBufferRecognitionRequest()
    private var recognitionTask: SFSpeechRecognitionTask?

    func requestAllPermissions(completion: @escaping (Bool) -> Void) {
        print("Requesting all permissions")
        let dispatchGroup = DispatchGroup()
        var allGranted = true

        dispatchGroup.enter()
        requestMicrophoneAccess { microphoneGranted in
            if !microphoneGranted {
                allGranted = false
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        requestSpeechAuthorization { speechAuthorized in
            if !speechAuthorized {
                allGranted = false
            }
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            if allGranted {
                print("All permissions granted")
                completion(true)
            } else {
                print("One or more permissions not granted")
                completion(false)
            }
        }
    }

    func requestMicrophoneAccess(completion: @escaping (Bool) -> Void) {
        print("Requesting microphone access")
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("Microphone access granted")
                } else {
                    print("Microphone access denied")
                }
                completion(granted)
            }
        }
    }

    func requestSpeechAuthorization(completion: @escaping (Bool) -> Void) {
        print("Requesting speech authorization")
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    print("Speech recognition authorized")
                    completion(true)
                default:
                    print("Speech recognition not authorized")
                    completion(false)
                }
            }
        }
    }

    func startTranscription(completion: @escaping (String?, Error?) -> Void) {
        // Stop the audio engine if it is running
        if audioEngine.isRunning {
            stopAudioEngineSafely()
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer not available")
            completion(nil, NSError(domain: "SpeechService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"]))
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            print("Configuring audio session")
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .allowBluetooth, .allowBluetoothA2DP, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session configured successfully")
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
            completion(nil, error)
            return
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        let inputNode = audioEngine.inputNode

        recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
            if let error = error {
                print("Recognition task error: \(error.localizedDescription)")
                completion(nil, error)
                return
            }
            if let result = result {
                print("Recognition task result: \(result.bestTranscription.formattedString)")
                completion(result.bestTranscription.formattedString, nil)
                if result.isFinal {
                    inputNode.removeTap(onBus: 0)
                    self.audioEngine.stop()
                    self.request.endAudio()
                }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }

        do {
            print("Preparing and starting audio engine")
            audioEngine.prepare()
            try audioEngine.start()
            print("Audio engine started successfully")
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
            completion(nil, error)
        }
    }

    func stopAudioEngineSafely() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionTask?.cancel()
            recognitionTask = nil
        }
    }
}


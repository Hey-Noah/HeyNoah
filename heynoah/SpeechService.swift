
// SpeechService.swift
import Foundation
import Speech
import AVFoundation
import UIKit // Added to access UIApplication

class SpeechService: NSObject, SFSpeechRecognizerDelegate, ObservableObject {
    static let transcriptionStatusNotification = Notification.Name("TranscriptionStatusChanged")
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var request = SFSpeechAudioBufferRecognitionRequest()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isHandlingError: Bool = false
    private var isTranscribing: Bool = false
    private var retryCount = 0
    private let maxRetryCount = 3

    override init() {
        super.init()
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    @objc private func handleAppWillResignActive() {
        print("App will resign active - keeping audio engine running in the background")
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to keep audio session active: \(error.localizedDescription)")
        }
    }

    @objc private func handleAppDidBecomeActive() {
        print("App did become active - ensuring transcription continues")
        if !audioEngine.isRunning {
            startTranscription { _, _ in }
        }
    }

    func requestAllPermissions(completion: @escaping (Bool) -> Void) {
        print("Requesting all permissions")
        let dispatchGroup = DispatchGroup()
        var allGranted = true

        dispatchGroup.enter()
        requestMicrophoneAccess { microphoneGranted in
            print("Microphone access granted: \(microphoneGranted)")
            if (!microphoneGranted) {
                allGranted = false
            }
            dispatchGroup.leave()
        }

        dispatchGroup.enter()
        requestSpeechAuthorization { speechAuthorized in
            print("Speech recognition authorized: \(speechAuthorized)")
            if (!speechAuthorized) {
                allGranted = false
            }
            dispatchGroup.leave()
        }

        dispatchGroup.notify(queue: .main) {
            if (allGranted) {
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
        AVAudioApplication.requestRecordPermission{ granted in
            DispatchQueue.main.async {
                print("Microphone access result: \(granted)")
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
                    print("Speech recognition not authorized: \(authStatus)")
                    completion(false)
                }
            }
        }
    }

    func startTranscription(completion: @escaping (String?, Error?) -> Void) {
        // Notify that initialization is starting
        NotificationCenter.default.post(name: SpeechService.transcriptionStatusNotification, object: nil, userInfo: ["status": "Initializing..."])
        // Set initializing text before starting transcription
        DispatchQueue.main.async {
            print("Initializing...")
        }
        guard !isTranscribing else {
            print("Transcription already in progress - skipping start")
            return
        } // Avoid starting transcription if already in progress
        isTranscribing = true

        // Stop the audio engine if it is running
        if audioEngine.isRunning {
            print("Audio engine running - stopping before reconfiguration")
            stopAudioEngineSafely()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Increased delay to ensure proper cleanup
            print("Configuring and starting audio engine for transcription")
            self.configureAndStartAudioEngine(completion: completion)
        }
    }

    private func configureAndStartAudioEngine(completion: @escaping (String?, Error?) -> Void) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            print("Speech recognizer not available")
            completion(nil, NSError(domain: "SpeechService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"]))
            isTranscribing = false
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            print("Configuring audio session")
            try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            print("Audio session configured successfully")
        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
            completion(nil, error)
            handleSpeechServiceError(error: error)
            isTranscribing = false
            return
        }

        request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        let inputNode = audioEngine.inputNode

        // Remove any existing tap before adding a new one
        inputNode.removeTap(onBus: 0)

        recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
            if let error = error as NSError?, error.domain == SFSpeechErrorDomain, error.code == 1101 {
                print("No speech detected, continuing without restarting.")
                return
            }

            if let error = error {
                print("Recognition task error: \(error.localizedDescription)")
                self.handleSpeechServiceError(error: error)
                return
            }
            if let result = result {
                completion(result.bestTranscription.formattedString, nil)
                // Automatically continue without restarting on final result
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
            // Notify that transcription is now listening
            NotificationCenter.default.post(name: SpeechService.transcriptionStatusNotification, object: nil, userInfo: ["status": "Listening..."])
            DispatchQueue.main.async {
                print("Listening...")
            }
        } catch {
            print("Failed to start audio engine: \(error.localizedDescription)")
            completion(nil, error)
            handleSpeechServiceError(error: error)
            isTranscribing = false
        }
    }

    func stopAudioEngineSafely() {
        if audioEngine.isRunning {
            print("Stopping audio engine safely")
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        isTranscribing = false
    }

    private func handleSpeechServiceError(error: Error) {
        guard !isHandlingError, retryCount < maxRetryCount else {
            print("Max retry limit reached or error handling in progress. No further retries.")
            isTranscribing = false
            return
        }
        isHandlingError = true
        retryCount += 1
        print("Error encountered: \(error.localizedDescription). Cooling down for 5 seconds before retrying. Retry count: \(retryCount)/\(maxRetryCount)")

        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            guard let self = self else { return }
            self.isHandlingError = false
            // Retry logic if needed
            self.startTranscription { _, _ in
                // Handle retry response
            }
        }
    }
}

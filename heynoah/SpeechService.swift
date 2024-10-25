// SpeechService.swift
import Foundation
import Speech
import AVFoundation
import UIKit

protocol SpeechServiceDelegate: AnyObject {
    func permissionsGranted()
}

class SpeechService: NSObject, SFSpeechRecognizerDelegate, ObservableObject {
    static let transcriptionStatusNotification = Notification.Name("TranscriptionStatusChanged")
    static let engineStartedNotification = Notification.Name("AudioEngineStarted")
    static let engineStoppedNotification = Notification.Name("AudioEngineStopped")
    private let speechRecognizer = SFSpeechRecognizer()
    private let audioEngine = AVAudioEngine()
    private var request = SFSpeechAudioBufferRecognitionRequest()
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isHandlingError: Bool = false
    private var isTranscribing: Bool = false
    private var retryCount = 0
    private let maxRetryCount = 3
    var permissionsGranted: Bool = false
    private var permissionsRequested: Bool = false
    weak var delegate: SpeechServiceDelegate?
    
    @Published var transcriptionText: String = "" // Add this property to hold transcription text

    override init() {
        super.init()
        setupNotifications()
        checkPermissionsStatus() // Check permissions status on initialization
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    private func checkPermissionsStatus() {
        // Check UserDefaults to see if permissions were requested before
        permissionsGranted = UserDefaults.standard.bool(forKey: "permissionsRequested")
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
        if permissionsGranted && !audioEngine.isRunning {
            startTranscription { _, _ in }
        }
    }

    func requestAllPermissions(completion: @escaping (Bool) -> Void) {
        guard !permissionsRequested else {
            print("Permissions already requested")
            completion(permissionsGranted)
            if permissionsGranted {
                delegate?.permissionsGranted()
            }
            return
        }

        print("Requesting all permissions")
        permissionsRequested = true
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
                self.permissionsGranted = true
                UserDefaults.standard.set(true, forKey: "permissionsRequested") // Save permissions state
                self.delegate?.permissionsGranted()
                completion(true)
            } else {
                print("One or more permissions not granted")
                self.permissionsGranted = false
                completion(false)
            }
        }
    }

    func requestMicrophoneAccess(completion: @escaping (Bool) -> Void) {
        print("Requesting microphone access")
        AVAudioApplication.requestRecordPermission { granted in
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
        guard permissionsGranted else {
            print("Permissions not granted - cannot start transcription")
            completion(nil, NSError(domain: "SpeechService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permissions not granted"]))
            return
        }

        // Set initial transcription text
        transcriptionText = "Initializing..."
        
        // Ensure only one recognition task runs at a time
        if isTranscribing || recognitionTask != nil {
            print("Transcription already in progress - skipping start")
            return
        }

        isTranscribing = true

        // Stop the audio engine if it is running
        if audioEngine.isRunning {
            print("Audio engine running - stopping before reconfiguration")
            stopAudioEngineSafely()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.permissionsGranted {
                print("Configuring and starting audio engine for transcription")
                self.configureAndStartAudioEngine(completion: completion)
            } else {
                print("Permissions not granted - cannot configure audio engine")
                completion(nil, NSError(domain: "SpeechService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Permissions not granted"]))
                self.isTranscribing = false
            }
        }
    }
    private func configureAndStartAudioEngine(completion: @escaping (String?, Error?) -> Void) {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            completion(nil, NSError(domain: "SpeechService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"]))
            isTranscribing = false
            return
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .measurement, options: [.mixWithOthers, .allowBluetooth, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)

            request = SFSpeechAudioBufferRecognitionRequest()
            request.shouldReportPartialResults = true

            let inputNode = audioEngine.inputNode
            inputNode.removeTap(onBus: 0) // Remove any existing tap
            recognitionTask = speechRecognizer.recognitionTask(with: request) { result, error in
                if let result = result {
                    completion(result.bestTranscription.formattedString, nil)
                    self.transcriptionText = result.bestTranscription.formattedString // Update transcription text
                }
                if let error = error {
                    completion(nil, error)
                }
            }

            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                self.request.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            NotificationCenter.default.post(name: SpeechService.engineStartedNotification, object: nil)

            // Notify that transcription is now listening
            DispatchQueue.main.async {
                self.transcriptionText = "Listening..."
            }

        } catch {
            completion(nil, error)
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
        NotificationCenter.default.post(name: SpeechService.engineStoppedNotification, object: nil) 
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
            NotificationCenter.default.post(name: SpeechService.engineStoppedNotification, object: nil) 
            guard let self = self else { return }
            self.isHandlingError = false
            // Retry logic if needed
            self.startTranscription { _, _ in
                // Handle retry response
            }
        }
    }
}

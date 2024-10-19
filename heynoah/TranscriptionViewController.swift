// TranscriptionViewController.swift
import UIKit
import AVFoundation
import Speech

class TranscriptionViewController: UIViewController {
    let transcriptionLabel = UILabel()
    var fontSize: CGFloat = 128
    var customName: String = "Noah"
    private var speechService: SpeechService
    private var notificationService: NotificationService
    private var currentTranscriptionTask: SFSpeechRecognitionTask?
    private var isTranscribing: Bool = false

    init(speechService: SpeechService, notificationService: NotificationService) {
        self.speechService = speechService
        self.notificationService = notificationService
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("viewDidLoad called")
        setupTranscriptionLabel()
        configureAudioSessionForBackground()
        startTranscription()
    }

    private func setupTranscriptionLabel() {
        print("Setting up transcription label")
        transcriptionLabel.frame = view.bounds
        transcriptionLabel.font = UIFont.systemFont(ofSize: fontSize)
        transcriptionLabel.textAlignment = .center
        transcriptionLabel.numberOfLines = 0
        transcriptionLabel.text = "Listening..."
        view.addSubview(transcriptionLabel)
    }

    private func configureAudioSessionForBackground() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.mixWithOthers, .allowBluetooth, .defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            print("Audio session configured for background use")
        } catch {
            print("Failed to configure audio session for background: \(error.localizedDescription)")
            showAlert(title: "Audio Session Error", message: "Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    func updateFontSize(_ size: CGFloat) {
        transcriptionLabel.font = UIFont.systemFont(ofSize: min(size, 256))
    }

    func updateTranscriptionHandler() {
        // Cancel the current transcription task if it's running
        stopTranscription()
        startTranscription()  // Restart transcription with updated settings
    }

    private func startTranscription() {
        guard !isTranscribing else { return }  // Prevent reinitialization if already transcribing
        isTranscribing = true
        stopTranscription()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.speechService.startTranscription { [weak self] transcription, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let error = error {
                        print("Transcription error: \(error.localizedDescription)")
                        self.transcriptionLabel.text = "Error: \(error.localizedDescription)"
                        if (error as NSError).domain == "kAFAssistantErrorDomain" && (error as NSError).code == 1101 {
                            self.showAlert(title: "Speech Recognition Error", message: "The speech recognition service is currently unavailable. Please try again later.")
                            self.handleAudioSessionInterruption()  // Handle interruption by resetting audio session
                        }
                        self.handleTranscriptionError()  // Handle error by resetting the transcription service
                        self.isTranscribing = false
                        return
                    }
                    if let transcription = transcription {
                        print("Transcription: \(transcription)")
                        self.transcriptionLabel.text = transcription
                        if transcription.localizedCaseInsensitiveContains(self.customName) {
                            self.notificationService.isNotificationPending(identifier: "NoahNotification") { [weak self] isPending in
                                guard let self = self else { return }
                                if !isPending {
                                    self.notificationService.sendLocalNotification(title: "Someone is speaking to you, \(self.customName)!", identifier: "NoahNotification")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func stopTranscription() {
        if let currentTranscriptionTask = currentTranscriptionTask {
            currentTranscriptionTask.cancel()
            self.currentTranscriptionTask = nil
        }
        speechService.stopAudioEngineSafely()
        isTranscribing = false
    }

    private func handleTranscriptionError() {
        // Retry starting the transcription after a small delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.startTranscription()
        }
    }

    private func handleAudioSessionInterruption() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            try AVAudioSession.sharedInstance().setActive(true)
            print("Audio session reactivated after interruption")
        } catch {
            print("Failed to reactivate audio session: \(error.localizedDescription)")
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}


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
    private var settingsManager: SettingsManager  // Added settingsManager reference
    private var currentTranscriptionTask: SFSpeechRecognitionTask?
    private var isTranscribing: Bool = false

    init(speechService: SpeechService, notificationService: NotificationService, settingsManager: SettingsManager) {
        self.speechService = speechService
        self.notificationService = notificationService
        self.settingsManager = settingsManager  // Initialize settingsManager
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
        updateAppearance() // Ensure appearance is updated initially
        startTranscription()
    }

    private func setupTranscriptionLabel() {
        print("Setting up transcription label")
        transcriptionLabel.frame = view.bounds
        transcriptionLabel.font = UIFont.systemFont(ofSize: settingsManager.fontSize)  // Use settingsManager for font size
        transcriptionLabel.textAlignment = .center
        transcriptionLabel.numberOfLines = 0
        transcriptionLabel.text = "Listening..."
        transcriptionLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(transcriptionLabel)
        updateAppearance() // Set appearance during initial setup
    }

    func updateAppearance() {
        let isDarkMode = settingsManager.isDarkMode  // Use settingsManager for dark mode status
        view.backgroundColor = isDarkMode ? .black : .white
        transcriptionLabel.textColor = isDarkMode ? .white : .black
        logAppearanceState("Appearance updated")
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateAppearance() // Update appearance when trait collection changes (e.g., dark mode)
        }
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
        print("Font size updated to: \(size)")
    }

    func updateTranscriptionHandler() {
        // Cancel the current transcription task if it's running
        stopTranscription()
        startTranscription()  // Restart transcription with updated settings
    }

    private func startTranscription() {
        guard !isTranscribing else { return }  // Prevent reinitialization if already transcribing
        isTranscribing = true
        print("Starting transcription")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            self.speechService.startTranscription { [weak self] transcription, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let error = error {
                        print("Transcription error: \(error.localizedDescription)")
                        self.transcriptionLabel.text = "Error: \(error.localizedDescription)"
                        self.updateAppearance() // Update appearance to ensure proper colors
                        self.transcriptionLabel.setNeedsDisplay() // Ensure display is refreshed
                        self.logAppearanceState("Error state applied to transcription label")
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
                        if transcription.isEmpty {
                            print("Warning: Transcription result is empty")
                        }
                        print("Updating transcription label text to: \(transcription)")
                        self.transcriptionLabel.text = transcription
                        self.updateAppearance() // Update appearance to ensure proper colors
                        self.transcriptionLabel.setNeedsLayout()  // Request a layout update
                        self.transcriptionLabel.layoutIfNeeded()  // Force layout update
                        self.transcriptionLabel.setNeedsDisplay()  // Ensure display is refreshed
                        print("Transcription label text after update: \(self.transcriptionLabel.text ?? "nil")")
                        self.logAppearanceState("Transcription updated")
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
            print("Stopping current transcription task")
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

    private func logAppearanceState(_ context: String) {
        let isDarkMode = settingsManager.isDarkMode
        print("\(context) - Dark Mode: \(isDarkMode), Label Text Color: \(transcriptionLabel.textColor?.description ?? "Unknown"), Background Color: \(view.backgroundColor?.description ?? "Unknown"), Label Text: \(transcriptionLabel.text ?? "nil")")
    }
}

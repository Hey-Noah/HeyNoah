// TranscriptionViewController.swift
import UIKit
import AVFoundation
import Speech
import Combine

class TranscriptionViewController: UIViewController, SpeechServiceDelegate {
    let transcriptionLabel = UILabel()
    var fontSize: CGFloat = 128
    var customName: String = "Noah"
    private var speechService: SpeechService
    private var notificationService: NotificationService
    private var settingsManager: SettingsManager  // Added settingsManager reference
    private var isTranscribing: Bool = false
    private var subscriptions = Set<AnyCancellable>()

    init(speechService: SpeechService, notificationService: NotificationService, settingsManager: SettingsManager) {
        self.speechService = speechService
        self.notificationService = notificationService
        self.settingsManager = settingsManager  // Initialize settingsManager
        super.init(nibName: nil, bundle: nil)
        self.speechService.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(handleTranscriptionStatusChange), name: SpeechService.transcriptionStatusNotification, object: nil)
        print("viewDidLoad called")
        speechService.requestAllPermissions { [weak self] granted in
            if granted {
                self?.initializeViewComponents()
            } else {
                self?.showAlert(title: "Permission Denied", message: "Permissions are required to proceed.")
            }
        }
    }

    private func initializeViewComponents() {
        setupTranscriptionLabel()
        configureAudioSessionForBackground()
        updateAppearance() // Ensure appearance is updated initially
    }

    func permissionsGranted() {
        // Permission callback; ensure UI and services are initialized after permissions are granted.
        initializeViewComponents()
    }

    private func setupTranscriptionLabel() {
        print("Setting up transcription label")
        transcriptionLabel.frame = view.bounds
        transcriptionLabel.font = UIFont.systemFont(ofSize: settingsManager.fontSize)  // Use settingsManager for font size
        transcriptionLabel.textAlignment = .center
        transcriptionLabel.numberOfLines = 0
        transcriptionLabel.text = "Initializing..."
        transcriptionLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(transcriptionLabel)
        updateAppearance() // Set appearance during initial setup
        
        speechService.$transcriptionText
            .receive(on: RunLoop.main)
            .sink { [weak self] newText in
                self?.processTranscriptionText(newText)
            }
            .store(in: &subscriptions) // Automatically update label
    }

    private func processTranscriptionText(_ transcription: String) {
        let words = transcription.split(separator: " ")
        var maskedWords: [String] = []
        
        for word in words {
            if settingsManager.isKidModeEnabled {
                let encodedWord = word.lowercased().data(using: .utf8)?.base64EncodedString() ?? ""
                if let emoji = settingsManager.kidUnfriendlyWords[encodedWord] {
                    maskedWords.append(emoji)
                } else {
                    maskedWords.append(String(word))
                }
            } else {
                maskedWords.append(String(word))
            }
        }
        
        let processedText = maskedWords.joined(separator: " ")
        transcriptionLabel.text = processedText
        checkForCustomName(in: processedText)
        while transcriptionLabel.isTextTruncated() {
            if let currentText = transcriptionLabel.text, let firstSpaceIndex = currentText.firstIndex(of: " ") {
                transcriptionLabel.text = String(currentText[currentText.index(after: firstSpaceIndex)...])
            } else {
                break
            }
        }
        self.updateAppearance() // Update appearance to ensure proper colors
        transcriptionLabel.setNeedsLayout()  // Request a layout update
        transcriptionLabel.layoutIfNeeded()  // Force layout update
        transcriptionLabel.setNeedsDisplay()  // Ensure display is refreshed
    }

    private func checkForCustomName(in text: String) {
        if text.localizedCaseInsensitiveContains(self.settingsManager.customName) {
            self.notificationService.isNotificationPending(identifier: "NoahNotification") { [weak self] isPending in
                guard let self = self else { return }
                if !isPending {
                    self.notificationService.sendLocalNotification(title: "Someone is speaking to you, \(self.settingsManager.customName)!", identifier: "NoahNotification")
                }
            }
        }
    }

    func updateAppearance() {
        let isDarkMode = settingsManager.isDarkMode  // Use settingsManager for dark mode status
        view.backgroundColor = isDarkMode ? .black : .white
        transcriptionLabel.textColor = isDarkMode ? .white : .black
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
    }

    func updateTranscriptionHandler() {
        // Cancel the current transcription task if it's running
        stopTranscription()
        startTranscription()  // Restart transcription with updated settings
    }

    func startTranscription() {
        guard !isTranscribing, speechService.permissionsGranted else { return }  // Prevent reinitialization if already transcribing or permissions are not granted
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
                        if (error as NSError).domain == "SpeechService" && (error as NSError).code == 1101 {
                            self.showAlert(title: "Speech Recognition Error", message: "The speech recognition service is currently unavailable. Please try again later.")
                            self.handleAudioSessionInterruption()  // Handle interruption by resetting audio session
                        }
                        self.handleTranscriptionError()  // Handle error by resetting the transcription service
                        self.isTranscribing = false
                        return
                    }
                    if let transcription = transcription {
                        if transcription.isEmpty {
                            print("Warning: Transcription result is empty")
                        }
                        self.processTranscriptionText(transcription)
                    }
                }
            }
        }
    }

    @objc private func handleTranscriptionStatusChange(notification: Notification) {
        if let status = notification.userInfo?["status"] as? String {
            transcriptionLabel.text = status
        }
    }

    private func stopTranscription() {
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

private extension UILabel {
    func isTextTruncated() -> Bool {
        guard let labelText = self.text else { return false }
        let size = CGSize(width: self.frame.width, height: .greatestFiniteMagnitude)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: self.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
        ]
        let textSize = (labelText as NSString).boundingRect(with: size, options: .usesLineFragmentOrigin, attributes: attributes, context: nil).size
        return textSize.height > self.bounds.size.height
    }
}

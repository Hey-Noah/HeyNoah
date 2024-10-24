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
    private var settingsManager: SettingsManager
    private var isTranscribing: Bool = false
    private var subscriptions = Set<AnyCancellable>() // Set for managing Combine subscriptions

    init(speechService: SpeechService, notificationService: NotificationService, settingsManager: SettingsManager) {
        self.speechService = speechService
        self.notificationService = notificationService
        self.settingsManager = settingsManager
        super.init(nibName: nil, bundle: nil)
        self.speechService.delegate = self // Set the delegate to self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = settingsManager.isDarkMode ? .black : .white
        setupTranscriptionLabel()
        requestPermissions()
        setupTranscriptionSubscription() // Set up the subscription to listen to transcription updates
    }

    // MARK: - Setup Transcription Label
    private func setupTranscriptionLabel() {
        transcriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        transcriptionLabel.font = UIFont.systemFont(ofSize: settingsManager.fontSize)
        transcriptionLabel.textAlignment = .center
        transcriptionLabel.numberOfLines = 0
        transcriptionLabel.text = "Initializing..."
        transcriptionLabel.textColor = settingsManager.isDarkMode ? .white : .black

        view.addSubview(transcriptionLabel)
        NSLayoutConstraint.activate([
            transcriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            transcriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            transcriptionLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor) // Center the label vertically
        ])
    }

    // MARK: - Request Permissions
    private func requestPermissions() {
        speechService.requestAllPermissions { [weak self] granted in
            if granted {
                DispatchQueue.main.async {
                    self?.permissionsGranted() // Call the delegate method directly
                }
            } else {
                DispatchQueue.main.async {
                    self?.showAlert(title: "Permission Denied", message: "Permissions are required to proceed.")
                }
            }
        }
    }

    // MARK: - SpeechServiceDelegate Method
    func permissionsGranted() {
        // Permission callback; ensure UI and services are initialized after permissions are granted.
        startTranscription()
    }

    // MARK: - Start Transcription
    private func startTranscription() {
        guard !isTranscribing else { return }
        isTranscribing = true
        speechService.startTranscription { [weak self] transcription, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    self.transcriptionLabel.text = "Error: \(error.localizedDescription)"
                    self.isTranscribing = false
                    return
                }
                if let transcription = transcription {
                    self.processTranscriptionText(transcription)
                }
            }
        }
    }

    // MARK: - Process Transcription Text
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
    }

    // MARK: - Check for Custom Name and Send Notification
    private func checkForCustomName(in text: String) {
        if text.localizedCaseInsensitiveContains(self.settingsManager.customName) {
            self.notificationService.isNotificationPending(identifier: "CustomNameNotification") { [weak self] isPending in
                guard let self = self else { return }
                if !isPending {
                    self.notificationService.sendLocalNotification(title: "Someone is speaking to you, \(self.settingsManager.customName)!", identifier: "CustomNameNotification")
                }
            }
        }
    }

    // MARK: - Update Appearance
    func updateAppearance() {
        view.backgroundColor = settingsManager.isDarkMode ? .black : .white
        transcriptionLabel.textColor = settingsManager.isDarkMode ? .white : .black
    }

    // MARK: - Update Font Size
    func updateFontSize(_ size: CGFloat) {
        transcriptionLabel.font = UIFont.systemFont(ofSize: size)
    }

    // MARK: - Setup Transcription Subscription
    private func setupTranscriptionSubscription() {
        // Subscribe to updates from the SpeechService's transcription text
        speechService.$transcriptionText
            .receive(on: RunLoop.main)
            .sink { [weak self] newText in
                guard let self = self else { return }
                self.processTranscriptionText(newText) // Always process new transcription text
            }
            .store(in: &subscriptions)
    }

    // MARK: - Alert Helper Method
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}

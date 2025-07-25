import Accounts
import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGASwift
import UIKit

class AudioPlayerViewController: UIViewController, AudioPlayerViewControllerNodeActionForwardingDelegate {
    @IBOutlet weak var imageViewContainerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var dataStackView: UIStackView!
    @IBOutlet weak var titleLabel: MEGALabel!
    @IBOutlet weak var subtitleLabel: MEGALabel!
    @IBOutlet weak var currentTimeLabel: MEGALabel!
    @IBOutlet weak var remainingTimeLabel: MEGALabel!
    @IBOutlet weak var timeSliderView: MEGASlider! {
        didSet {
            timeSliderView.minimumValue = 0
            timeSliderView.maximumValue = 1
        }
    }
    @IBOutlet weak var goBackwardButton: MEGAPlayerButton!
    @IBOutlet weak var previousButton: MEGAPlayerButton!
    @IBOutlet weak var playPauseButton: MEGAPlayerButton!
    @IBOutlet weak var nextButton: MEGAPlayerButton!
    @IBOutlet weak var goForwardButton: MEGAPlayerButton!
    @IBOutlet weak var shuffleButton: MEGASelectedButton!
    @IBOutlet weak var repeatButton: MEGASelectedButton!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var gotoplaylistButton: UIButton!
    @IBOutlet weak var playbackSpeedButton: UIButton!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    private var pendingDragEvent: Bool = false
    private var playerType: PlayerType = .default
    
    private var selectedNodeActionTypeEntity: NodeActionTypeEntity?
    
    // MARK: - Internal properties
    private(set) var viewModel: AudioPlayerViewModel
    
    init?(coder: NSCoder, viewModel: AudioPlayerViewModel) {
        self.viewModel = viewModel
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.invokeCommand = { [weak self] command in
            self?.executeCommand(command)
        }
        
        viewModel.dispatch(.onViewDidLoad)
        
        configureActivityIndicatorViewColor()
        
        configureImages()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed || presentingViewController?.isBeingDismissed == true {
            viewModel.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal))
        } else {
            if let selectedNodeActionTypeEntity, isSelectingSupportedNodeActionType(selectedNodeActionTypeEntity) {
                viewModel.dispatch(.viewWillDisappear(reason: .systemPushedAnotherView))
            } else {
                viewModel.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal))
            }
            selectedNodeActionTypeEntity = nil
        }
    }
    
    /// Overriding dismiss function to detect dismissal of current view controller triggered from navigation controller's dismissal
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        viewModel.dispatch(.viewWillDisappear(reason: .userInitiatedDismissal))
    }
    
    deinit {
        MEGALogDebug("[AudioPlayer] deallocating AudioPlayerViewController instance")
        removeDelegates()
    }
    
    // MARK: - Private functions
    
    private func configureImages() {
        imageView.image = MEGAAssets.UIImage.image(named: "filetype_audio")
        imageView.layer.cornerRadius = 16
        imageView.clipsToBounds = true 

        goBackwardButton.setImage(MEGAAssets.UIImage.image(named: "goBackward15"), for: .normal)
        previousButton.setImage(MEGAAssets.UIImage.image(named: "backTrack"), for: .normal)
        playPauseButton.setImage(MEGAAssets.UIImage.image(named: "play"), for: .normal)
        nextButton.setImage(MEGAAssets.UIImage.image(named: "fastForward"), for: .normal)
        goForwardButton.setImage(MEGAAssets.UIImage.image(named: "goForward15"), for: .normal)

        shuffleButton.setImage(MEGAAssets.UIImage.image(named: "shuffleAudio"), for: .normal)
        repeatButton.setImage(MEGAAssets.UIImage.image(named: "repeatAudio"), for: .normal)
        playbackSpeedButton.setImage(MEGAAssets.UIImage.image(named: "normal"), for: .normal)
        gotoplaylistButton.setImage(MEGAAssets.UIImage.image(named: "viewPlaylist"), for: .normal)

        moreButton.setImage(MEGAAssets.UIImage.image(named: "moreNavigationBar"), for: .normal)
    }
    
    private func isSelectingSupportedNodeActionType(_ selectedNodeActionTypeEntity: NodeActionTypeEntity) -> Bool {
        selectedNodeActionTypeEntity == .import
        || selectedNodeActionTypeEntity == .download
    }
    
    private func configureActivityIndicatorViewColor() {
        activityIndicatorView.color = TokenColors.Icon.secondary
    }
    
    private func removeDelegates() {
        viewModel.dispatch(.removeDelegates)
    }
    
    private func updatePlayerStatus(currentTime: String, remainingTime: String, percentage: Float, isPlaying: Bool) {
        currentTimeLabel.text = currentTime
        remainingTimeLabel.text = remainingTime
        
        updateSliderValueIfNeeded(percentage)
        
        playPauseButton.tintColor = TokenColors.Icon.primary
        playPauseButton.setImage((isPlaying ? MEGAAssets.UIImage.pause : MEGAAssets.UIImage.play).withTintColor(TokenColors.Icon.primary, renderingMode: .alwaysTemplate), for: .normal)
        
        if timeSliderView.value == 1.0 {
            timeSliderView.cancelTracking(with: nil)
            if pendingDragEvent {
                pendingDragEvent = false
            }
        }
    }
    
    private func updateSliderValueIfNeeded(_ newValue: Float) {
        guard !pendingDragEvent else { return }
        
        timeSliderView.setValue(newValue, animated: false)
    }
    
    private func updateCurrentItem(name: String, artist: String, thumbnail: UIImage?, nodeSize: String?) {
        titleLabel.text = name
        subtitleLabel.text = artist
        
        imageView.image = thumbnail ?? MEGAAssets.UIImage.image(named: "filetype_audio")
    }
    
    private func updateRepeat(_ status: RepeatMode) {
        switch status {
        case .none, .loop:
            repeatButton.setImage(MEGAAssets.UIImage.repeatAudio, for: .normal)
        case .repeatOne:
            repeatButton.setImage(MEGAAssets.UIImage.repeatOneAudio, for: .normal)
        }
        updateRepeatButtonAppearance(status: status)
    }
    
    private func updateSpeed(_ mode: SpeedMode) {
        let image: UIImage = switch mode {
        case .normal: MEGAAssets.UIImage.normal.withRenderingMode(.alwaysTemplate)
        case .oneAndAHalf: MEGAAssets.UIImage.oneAndAHalf.withRenderingMode(.alwaysTemplate)
        case .double: MEGAAssets.UIImage.double.withRenderingMode(.alwaysTemplate)
        case .half: MEGAAssets.UIImage.half.withRenderingMode(.alwaysTemplate)
        }
        
        playbackSpeedButton.setImage(image, for: .normal)
        playbackSpeedButton.tintColor = mode == .normal ? TokenColors.Icon.primary : TokenColors.Components.interactive
    }
    
    private func updateShuffle(_ status: Bool) {
        updateShuffleButtonAppearance(status: status)
        shuffleButton.isSelected = status
    }
    
    private func updateRepeatButtonAppearance(status: RepeatMode) {
        repeatButton.tintColor = switch status {
        case .none: TokenColors.Icon.primary
        case .loop, .repeatOne: TokenColors.Components.interactive
        }
    }
    
    private func updateShuffleButtonAppearance(status: Bool) {
        shuffleButton.tintColor = status ? TokenColors.Components.interactive : TokenColors.Icon.primary
        shuffleButton.setImage(MEGAAssets.UIImage.shuffleAudio, for: .normal)
    }
    
    private func refreshStateOfLoadingView(_ enabled: Bool) {
        activityIndicatorView.isHidden = !enabled
        if enabled {
            activityIndicatorView.startAnimating()
            hideInfoLabels()
        } else {
            activityIndicatorView.stopAnimating()
            showInfoLabels()
        }
    }
    
    private func hideInfoLabels() {
        titleLabel.isHidden = true
        subtitleLabel.isHidden = true
    }
    
    private func showInfoLabels() {
        titleLabel.isHidden = false
        subtitleLabel.isHidden = false
    }
    
    private func userInteraction(enabled: Bool, isSingleTrackPlayer: Bool) {
        timeSliderView.isUserInteractionEnabled = enabled
        goBackwardButton.isEnabled = enabled
        previousButton.isEnabled = enabled
        playPauseButton.isEnabled = enabled
        goForwardButton.isEnabled = enabled
        repeatButton.isEnabled = enabled
        playbackSpeedButton.isEnabled = enabled
        refreshMultiTrackControlsState(enabled: enabled && !isSingleTrackPlayer)
    }
    
    private func updateCloseButtonState() {
        closeButton.setTitle(Strings.Localizable.close, for: .normal)
        configureCloseButtonColor()
    }
    
    private func refreshMultiTrackControlsState(enabled: Bool) {
        let activeShuffleButtonColor = shuffleButton.isSelected ? TokenColors.Components.interactive : TokenColors.Icon.primary
        setForegroundColor(for: shuffleButton, color: enabled ? activeShuffleButtonColor : TokenColors.Icon.disabled)
        shuffleButton.isEnabled = enabled
        setForegroundColor(for: gotoplaylistButton, color: enabled ? TokenColors.Icon.primary : TokenColors.Icon.disabled)
        gotoplaylistButton.isEnabled = enabled
        setForegroundColor(for: nextButton, color: enabled ? TokenColors.Icon.primary : TokenColors.Icon.disabled)
        nextButton.isEnabled = enabled
    }
    
    private func configureCloseButtonColor() {
        closeButton.setTitleColor(TokenColors.Text.primary, for: .normal)
    }
    
    private func updateMoreButtonState() {
        moreButton.isHidden = playerType == .offline
    }
    
    // MARK: - UI configurations
    private func updateAppearance() {
        configureViewsColor()
        viewModel.dispatch(.refreshRepeatStatus)
        viewModel.dispatch(.refreshShuffleStatus)
        
        updateCloseButtonState()
        updateMoreButtonState()
        style()
        
        let playbackControlButtons = [ goBackwardButton, previousButton, playPauseButton, nextButton, goForwardButton ]
        let bottomViewButtons = [ shuffleButton, repeatButton, playbackSpeedButton, gotoplaylistButton ]
        
        playbackControlButtons
            .compactMap { $0 }
            .forEach { [weak self] in self?.setForegroundColor(for: $0, color: TokenColors.Icon.primary) }
        
        bottomViewButtons
            .compactMap { $0 }
            .forEach { [weak self] in self?.setForegroundColor(for: $0, color: TokenColors.Icon.primary) }
    }
    
    private func configureViewsColor() {
        configureBottomViewColor()
        configureViewBackgroundColor()
        configureCloseButtonColor()
    }
    
    private func configureBottomViewColor() {
        bottomView.backgroundColor = TokenColors.Background.page
    }
    
    private func configureViewBackgroundColor() {
        view.backgroundColor = TokenColors.Background.page
    }
    
    private func style() {
        titleLabel.textColor = TokenColors.Text.primary
        subtitleLabel.textColor = TokenColors.Text.secondary
        currentTimeLabel.textColor = TokenColors.Text.secondary
        remainingTimeLabel.textColor = TokenColors.Text.secondary
        timeSliderView.tintColor = TokenColors.Background.surface2
        
        closeButton.titleLabel?.adjustsFontForContentSizeCategory = true
        configureViewsColor()
    }
    
    // MARK: - UI actions
    @IBAction func shuffleButtonAction(_ sender: Any) {
        shuffleButton.isSelected = !shuffleButton.isSelected
        viewModel.dispatch(.onShuffle(active: shuffleButton.isSelected))
    }
    
    @IBAction func goBackwardsButtonAction(_ sender: Any) {
        viewModel.dispatch(.onGoBackward)
    }
    
    @IBAction func previousButtonAction(_ sender: Any) {
        viewModel.dispatch(.onPrevious)
    }
    
    @IBAction func playPauseButtonAction(_ sender: Any) {
        viewModel.dispatch(.onPlayPause)
    }
    
    @IBAction func nextButtonAction(_ sender: Any) {
        viewModel.dispatch(.onNext)
    }
    
    @IBAction func goForwardButtonAction(_ sender: Any) {
        viewModel.dispatch(.onGoForward)
    }
    
    @IBAction func repeatButtonAction(_ sender: Any) {
        viewModel.dispatch(.onRepeatPressed)
    }
    
    @IBAction func goToPlaylistButtonAction(_ sender: Any) {
        viewModel.dispatch(.showPlaylist)
    }
    
    @IBAction func timeSliderValueChangeAction(_ sender: Any, forEvent event: UIEvent) {
        guard let phase = event.allTouches?.first?.phase,
              phase == .began || phase == .ended else { return }
        
        pendingDragEvent = (phase == .began)
        if phase == .ended {
            viewModel.dispatch(.updateCurrentTime(percentage: timeSliderView.value))
        }
    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        viewModel.dispatch(.showActionsforCurrentNode(sender: sender))
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        closeButtonAction()
    }
    
    private func importBarButtonPressed(_ button: UIBarButtonItem) {
        viewModel.dispatch(.import)
    }
    
    private func sendToContactBarButtonPressed(_ button: UIBarButtonItem) {
        viewModel.dispatch(.sendToChat)
    }
    
    private func shareBarButtonPressed(_ button: UIBarButtonItem) {
        viewModel.dispatch(.share(sender: button))
    }
    
    @objc private func closeButtonAction() {
        viewModel.dispatch(.dismiss)
    }
    
    @objc private func moreButtonAction(_ sender: Any) {
        viewModel.dispatch(.showActionsforCurrentNode(sender: sender))
    }
    
    @IBAction func changePlaybackSpeedButtonAction(_ sender: Any) {
        viewModel.dispatch(.onChangeSpeedModePressed)
    }
    
    private func presentAudioPlaybackContinuation(fileName: String, playbackTime: TimeInterval) {
        let alertViewController = UIAlertController(
            title: Strings.Localizable.Media.Audio.PlaybackContinuation.Dialog.title,
            message: Strings.Localizable.Media.Audio.PlaybackContinuation
                .Dialog.description(fileName, playbackTime.timeString),
            preferredStyle: .alert
        )
        [
            UIAlertAction(
                title: Strings.Localizable.Media.Audio.PlaybackContinuation.Dialog.restart,
                style: .default
            ) { [weak self] _ in
                self?.viewModel.dispatch(.onSelectRestartPlaybackContinuationDialog)
            },
            UIAlertAction(
                title: Strings.Localizable.Media.Audio.PlaybackContinuation.Dialog.resume,
                style: .default
            ) { [weak self] _ in
                self?.viewModel.dispatch(
                    .onSelectResumePlaybackContinuationDialog(playbackTime: playbackTime)
                )
            }
        ].forEach { alertViewController.addAction($0) }
        present(alertViewController, animated: true)
    }
    
    // MARK: - Execute command
    func executeCommand(_ command: AudioPlayerViewModel.Command) {
        switch command {
        case .reloadPlayerStatus(let currentTime, let remainingTime, let percentage, let isPlaying):
            updatePlayerStatus(currentTime: currentTime, remainingTime: remainingTime, percentage: percentage, isPlaying: isPlaying)
        case .reloadNodeInfo(let name, let artist, let thumbnail, let nodeSize):
            updateCurrentItem(name: name, artist: artist, thumbnail: thumbnail, nodeSize: nodeSize)
        case .reloadThumbnail(let thumbnail):
            imageView.image = thumbnail
        case .showLoading(let enabled):
            timeSliderView.isUserInteractionEnabled = !enabled
            refreshStateOfLoadingView(enabled)
        case .updateRepeat(let status):
            updateRepeat(status)
        case .updateSpeed(let mode):
            updateSpeed(mode)
        case .updateShuffle(let status):
            updateShuffle(status)
        case .configureDefaultPlayer:
            playerType = .`default`
            updateAppearance()
        case .configureOfflinePlayer:
            playerType = .offline
            updateAppearance()
        case .configureFileLinkPlayer:
            playerType = .fileLink
            updateAppearance()
        case .enableUserInteraction(let enabled, let isSingleTrackPlayer):
            userInteraction(enabled: enabled, isSingleTrackPlayer: isSingleTrackPlayer)
        case .didPausePlayback, .didResumePlayback:
            setForegroundColor(for: playPauseButton, color: TokenColors.Icon.primary)
        case .displayPlaybackContinuationDialog(let fileName, let playbackTime):
            presentAudioPlaybackContinuation(fileName: fileName, playbackTime: playbackTime)
        }
    }
    
    private func setForegroundColor(for button: UIButton, color: UIColor) {
        button.tintColor = color
        button.setImage(button.currentImage?.withTintColor(color, renderingMode: .alwaysTemplate), for: .normal)
    }
    
    // MARK: - AudioPlayerViewControllerNodeActionForwardingDelegate
    
    func didSelectNodeActionTypeMenu(_ nodeActionTypeEntity: NodeActionTypeEntity) {
        selectedNodeActionTypeEntity = nodeActionTypeEntity
    }
}

// MARK: - Ads
extension AudioPlayerViewController: AdsSlotViewControllerProtocol {
    public var adsSlotUpdates: AnyAsyncSequence<AdsSlotConfig?> {
        SingleItemAsyncSequence(
            item: AdsSlotConfig(displayAds: true)
        ).eraseToAnyAsyncSequence()
    }
}

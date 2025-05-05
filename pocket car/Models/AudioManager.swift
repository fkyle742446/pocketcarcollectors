import AVFoundation
import AudioToolbox

class AudioManager {
    static let shared = AudioManager()
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var splashMusicPlayer: AVAudioPlayer?
    private var slotMusicPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?
    
    // Unified volume levels
    private let maxVolume: Float = 0.15 // Background music
    private let effectsVolume: Float = 0.15 // Sound effects
    private let buttonVolume: Float = 0.15 // Button sounds
    
    private let fadeDuration: TimeInterval = 2.0
    private let fadeSteps: Float = 100.0
    
    init() {
        setupAllMusic()
    }
    
    private func setupAllMusic() {
        setupBackgroundMusic()
        setupSplashMusic()
        setupSlotMusic()
    }
    
    private func setupBackgroundMusic() {
        guard let url = Bundle.main.url(forResource: "Background", withExtension: "mp3") else {
            print("Could not find Background.mp3")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1
            backgroundMusicPlayer?.volume = 0
        } catch {
            print("Error loading background music: \(error)")
        }
    }
    
    private func setupSplashMusic() {
        guard let url = Bundle.main.url(forResource: "SplashScreen", withExtension: "mp3") else {
            print("Could not find SplashScreen.mp3")
            return
        }
        
        do {
            splashMusicPlayer = try AVAudioPlayer(contentsOf: url)
            splashMusicPlayer?.volume = 0
        } catch {
            print("Error loading splash music: \(error)")
        }
    }
    
    private func setupSlotMusic() {
        guard let url = Bundle.main.url(forResource: "SlotMusic", withExtension: "mp3") else {
            print("Could not find SlotMusic.mp3")
            return
        }
        
        do {
            slotMusicPlayer = try AVAudioPlayer(contentsOf: url)
            slotMusicPlayer?.volume = 0
        } catch {
            print("Error loading slot music: \(error)")
        }
    }
    
    private func fadeMusic(player: AVAudioPlayer?, from: Float, to: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        guard let player = player else { return }
        
        let stepCount = Int(self.fadeSteps)
        let stepDuration = duration / TimeInterval(stepCount)
        let volumeDelta = (to - from) / self.fadeSteps
        
        player.volume = from
        if from == 0 { player.play() }
        
        var step = 0
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            step += 1
            if step >= stepCount {
                player.volume = to
                timer.invalidate()
                if to == 0 { player.stop() }
                completion?()
            } else {
                let progress = Float(step) / self.fadeSteps
                let easedProgress = sin(Float.pi * 0.5 * progress)
                player.volume = from + ((to - from) * easedProgress)
            }
        }
    }
    
    func startBackgroundMusic() {
        fadeMusic(player: backgroundMusicPlayer, from: 0, to: maxVolume, duration: fadeDuration)
    }
    
    func stopBackgroundMusic(completion: (() -> Void)? = nil) {
        fadeMusic(player: backgroundMusicPlayer, from: backgroundMusicPlayer?.volume ?? maxVolume, to: 0, duration: fadeDuration, completion: completion)
    }
    
    func playSplashMusic() {
        fadeMusic(player: splashMusicPlayer, from: 0, to: maxVolume, duration: fadeDuration)
    }
    
    func stopSplashMusic(completion: (() -> Void)? = nil) {
        fadeMusic(player: splashMusicPlayer, from: splashMusicPlayer?.volume ?? maxVolume, to: 0, duration: fadeDuration, completion: completion)
    }
    
    func playSlotMusic() {
        fadeMusic(player: backgroundMusicPlayer, from: backgroundMusicPlayer?.volume ?? maxVolume, to: 0, duration: fadeDuration * 1.5) { [weak self] in
            guard let self = self else { return }
            self.backgroundMusicPlayer?.stop()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration * 0.5) {
            self.fadeMusic(player: self.slotMusicPlayer, from: 0, to: self.maxVolume, duration: self.fadeDuration)
        }
    }
    
    func stopSlotMusic() {
        fadeMusic(player: slotMusicPlayer, from: slotMusicPlayer?.volume ?? maxVolume, to: 0, duration: fadeDuration * 1.5) { [weak self] in
            guard let self = self else { return }
            self.slotMusicPlayer?.stop()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration * 0.5) {
            self.fadeMusic(player: self.backgroundMusicPlayer, from: 0, to: self.maxVolume, duration: self.fadeDuration)
        }
    }
    
    func playPurchaseSound() {
        playSound(named: "purchase_sound", volume: effectsVolume)
    }
    
    func playToggleSound() {
        AudioServicesPlaySystemSound(1104)
    }
    
    func playCardTapSound() {
        AudioServicesPlaySystemSound(1520)
    }
    
    func playSellSound() {
        playSound(named: "sell", volume: effectsVolume)
    }
    
    func playButtonPress() {
        playSound(named: "booster_open", volume: buttonVolume)
    }
    
    func playNextCard() {
        playSound(named: "next_card", volume: buttonVolume)
    }
    
    private func playSound(named: String, volume: Float = 0.15) {
        guard let path = Bundle.main.url(forResource: named, withExtension: "mp3") else {
            print("Sound file not found: \(named)")
            return
        }
        
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: path)
            audioPlayer.volume = volume
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        } catch {
            print("Could not play sound: \(error.localizedDescription)")
        }
    }
}

import AVFoundation
import AudioToolbox

class AudioManager {
    static let shared = AudioManager()
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?
    private let maxBackgroundVolume: Float = 0.3
    
    init() {
        setupBackgroundMusic()
    }
    
    private func setupBackgroundMusic() {
        guard let url = Bundle.main.url(forResource: "Background", withExtension: "mp3") else {
            print("Could not find Background.mp3")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1
            backgroundMusicPlayer?.volume = maxBackgroundVolume
            startBackgroundMusic()
        } catch {
            print("Error loading background music: \(error)")
        }
    }
    
    func startBackgroundMusic() {
        fadeTimer?.invalidate()
        backgroundMusicPlayer?.volume = 0
        backgroundMusicPlayer?.play()
        fadeInBackgroundMusic()
    }
    
    func fadeOutBackgroundMusic() {
        fadeTimer?.invalidate()
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.backgroundMusicPlayer else {
                timer.invalidate()
                return
            }
            
            if player.volume > 0 {
                player.volume = max(player.volume - 0.01, 0)
            } else {
                timer.invalidate()
            }
        }
    }
    
    func fadeInBackgroundMusic() {
        fadeTimer?.invalidate()
        backgroundMusicPlayer?.play()
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, let player = self.backgroundMusicPlayer else {
                timer.invalidate()
                return
            }
            
            if player.volume < self.maxBackgroundVolume {
                player.volume = min(player.volume + 0.01, self.maxBackgroundVolume)
            } else {
                timer.invalidate()
            }
        }
    }
    
    func stopBackgroundMusic() {
        fadeTimer?.invalidate()
        backgroundMusicPlayer?.stop() 
        backgroundMusicPlayer?.volume = 0 
    }
    
    func playPurchaseSound() {
        playSound(named: "purchase_sound")
    }
    
    func playToggleSound() {
        AudioServicesPlaySystemSound(1104)
    }
    
    func playCardTapSound() {
        AudioServicesPlaySystemSound(1520)
    }
    
    func playSellSound() {
        AudioServicesPlaySystemSound(1122)  
    }
    
    private func playSound(named: String) {
        guard let path = Bundle.main.url(forResource: named, withExtension: "mp3") else {
            print("Sound file not found: \(named)")
            return
        }
        
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: path)
            audioPlayer.volume = 0.7
            audioPlayer.prepareToPlay()
            audioPlayer.play()
        } catch {
            print("Could not play sound: \(error.localizedDescription)")
        }
    }
}

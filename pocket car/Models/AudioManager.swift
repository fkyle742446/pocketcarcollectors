import AVFoundation
import AudioToolbox

class AudioManager {
    static let shared = AudioManager()
    
    private init() {}
    
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

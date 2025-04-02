import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    private var audioPlayer: AVAudioPlayer?
    
    private init() {}
    
    func playPurchaseSound() {
        playSound(named: "purchase_sound")
    }
    
    func playSellSound() {
        playSound(named: "sell")
    }
    
    private func playSound(named: String) {
        guard let path = Bundle.main.url(forResource: named, withExtension: "mp3") else {
            print("Sound file not found: \(named)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: path)
            audioPlayer?.volume = 0.7
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Could not play sound: \(error.localizedDescription)")
        }
    }
}

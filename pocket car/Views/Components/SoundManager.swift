import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    private var audioPlayers: [URL: AVAudioPlayer] = [:]
    
    private init() {} // Make init private for singleton
    
    func playSound(for rarity: CardRarity) {
        let soundName: String
        let volume: Float
        
        switch rarity {
        case .common:
            soundName = "common_reveal"
            volume = 0.7
        case .rare:
            soundName = "rare_reveal"
            volume = 0.7
        case .epic:
            soundName = "epic_reveal"
            volume = 0.7
        case .legendary:
            soundName = "legendary_reveal"
            volume = 0.7
        case .HolyT:
            soundName = "legendary_reveal"
            volume = 0.9
        }
        
        guard let path = Bundle.main.path(forResource: soundName, ofType: "mp3") else {
            print("Failed to find sound file: \(soundName)")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        if let existingPlayer = audioPlayers[url] {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if existingPlayer.volume > 0 {
                    existingPlayer.volume -= 0.1
                } else {
                    timer.invalidate()
                    existingPlayer.stop()
                    self.audioPlayers.removeValue(forKey: url)
                }
            }
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0
            player.play()
            audioPlayers[url] = player
            
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                if player.volume < volume {
                    player.volume += 0.1
                } else {
                    timer.invalidate()
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) {
                Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                    if player.volume > 0 {
                        player.volume -= 0.1
                    } else {
                        timer.invalidate()
                        self.audioPlayers.removeValue(forKey: url)
                    }
                }
            }
        } catch {
            print("Failed to play sound: \(error.localizedDescription)")
        }
    }
}

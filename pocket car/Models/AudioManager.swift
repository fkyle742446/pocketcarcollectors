import AVFoundation
import AudioToolbox

class AudioManager: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioManager()
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var splashMusicPlayer: AVAudioPlayer?
    private var slotMusicPlayer: AVAudioPlayer?
    private var boosterOpeningMusicPlayer: AVAudioPlayer?
    // private var fadeTimer: Timer?
    
    private let maxMusicVolume: Float = 0.3
    private let effectsVolume: Float = 0.15
    private let buttonVolume: Float = 0.15
    
    private let fadeDuration: TimeInterval = 1.5
    private let fadeSteps: Float = 100.0
    
    private enum ThematicMusicState {
        case none
        case background
        case splash
        case slot
        case boosterOpening
    }
    private var currentThematicMusic: ThematicMusicState = .none
    private var isTransitioningMusic: Bool = false // Pour éviter des commandes concurrentes
    private var effectPlayers: [AVAudioPlayer] = []
    
    override init() {
        super.init()
        setupAudioSession()
        setupAllMusic()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    private func setupAllMusic() {
        setupBackgroundMusic()
        setupSplashMusic()
        setupSlotMusic()
        setupBoosterOpeningMusic()
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
    
    private func setupBoosterOpeningMusic() {
        guard let url = Bundle.main.url(forResource: "BoosterOpenTheme", withExtension: "mp3") else {
            print("Could not find BoosterOpenTheme.mp3")
            return
        }
        
        do {
            boosterOpeningMusicPlayer = try AVAudioPlayer(contentsOf: url)
            boosterOpeningMusicPlayer?.volume = 0
        } catch {
            print("Error loading booster opening music: \(error)")
        }
    }
    
    private func fadeMusic(player: AVAudioPlayer?, from: Float, to: Float, duration: TimeInterval, completion: (() -> Void)? = nil) {
        guard let player = player else {
            completion?() // Appeler completion même si le player est nil pour ne pas bloquer la chaîne
            return
        }
        
        // Invalider tout timer de fondu existant pour CE player spécifique (si on avait un mécanisme pour ça)
        // Pour l'instant, on se fie à la création de nouveaux timers.

        let stepCount = Int(self.fadeSteps)
        let stepDuration = duration / TimeInterval(stepCount)
        let volumeDelta = (to - from) / self.fadeSteps // Non utilisé avec l'easing actuel
        
        // Si on fait un fondu entrant et que le player ne joue pas, le préparer et le démarrer
        if to > 0 && !player.isPlaying {
            player.volume = 0 // S'assurer qu'il commence à 0 avant de jouer
            player.prepareToPlay()
            player.play()
        } else if to == 0 && from == 0 && !player.isPlaying { // Si on demande un fondu vers 0 d'un son déjà à 0 et arrêté
            completion?()
            return
        } else {
            player.volume = from // Définir le volume initial pour le fondu
        }
        
        var step = 0
        Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak player] timer in
            guard let strongPlayer = player else { // S'assurer que le player existe toujours
                timer.invalidate()
                completion?() // Appeler completion même si le player a disparu
                return
            }

            step += 1
            if step >= stepCount {
                strongPlayer.volume = to
                timer.invalidate()
                if to == 0 {
                    strongPlayer.stop() // Arrêter après le fondu sortant complet
                    strongPlayer.currentTime = 0 // Réinitialiser pour la prochaine lecture
                }
                completion?()
            } else {
                let progress = Float(step) / Float(stepCount) // Assurer la division flottante
                // Utiliser une courbe d'easing (sinusoïdale pour adoucir le début et la fin)
                let easedProgress = sin(progress * Float.pi * 0.5) // Fondu entrant (ease-out)
                // Pour un fondu sortant (ease-in), on pourrait inverser : 1.0 - cos(progress * Float.pi * 0.5)
                // Ou simplement laisser l'ease-out pour les deux, c'est souvent acceptable.
                strongPlayer.volume = from + (to - from) * easedProgress
            }
        }
    }
    
    func startBackgroundMusic() {
        guard !isTransitioningMusic && currentThematicMusic != .background else { return }
        isTransitioningMusic = true
        
        // Arrêter instantanément les autres musiques thématiques si elles jouaient
        splashMusicPlayer?.stop(); splashMusicPlayer?.volume = 0
        slotMusicPlayer?.stop(); slotMusicPlayer?.volume = 0
        boosterOpeningMusicPlayer?.stop(); boosterOpeningMusicPlayer?.volume = 0
        
        currentThematicMusic = .background
        fadeMusic(player: backgroundMusicPlayer, from: backgroundMusicPlayer?.volume ?? 0, to: maxMusicVolume, duration: fadeDuration) { [weak self] in
            self?.isTransitioningMusic = false
        }
    }
    
    // stopBackgroundMusic reste simple car généralement appelé quand l'app se ferme ou change majeur de contexte.
    func stopBackgroundMusic(completion: (() -> Void)? = nil) {
        guard !isTransitioningMusic else { completion?(); return }
        isTransitioningMusic = true
        currentThematicMusic = .none
        fadeMusic(player: backgroundMusicPlayer, from: backgroundMusicPlayer?.volume ?? maxMusicVolume, to: 0, duration: fadeDuration) { [weak self] in
            self?.isTransitioningMusic = false
            completion?()
        }
    }
    
    func playSplashMusic() {
        guard !isTransitioningMusic && currentThematicMusic != .splash else { return }
        isTransitioningMusic = true

        backgroundMusicPlayer?.stop(); backgroundMusicPlayer?.volume = 0
        slotMusicPlayer?.stop(); slotMusicPlayer?.volume = 0
        boosterOpeningMusicPlayer?.stop(); boosterOpeningMusicPlayer?.volume = 0
        
        currentThematicMusic = .splash
        fadeMusic(player: splashMusicPlayer, from: 0, to: maxMusicVolume, duration: fadeDuration) { [weak self] in
            self?.isTransitioningMusic = false
        }
    }

    func stopSplashMusic(completion: (() -> Void)? = nil) {
        guard !isTransitioningMusic else { completion?(); return }
        // Ne pas changer currentThematicMusic ici, car on veut potentiellement relancer la musique de fond
        isTransitioningMusic = true
        fadeMusic(player: splashMusicPlayer, from: splashMusicPlayer?.volume ?? maxMusicVolume, to: 0, duration: fadeDuration) { [weak self] in
            self?.isTransitioningMusic = false
            completion?()
            // Optionnel: relancer la musique de fond après l'arrêt du splash
            // self?.startBackgroundMusic()
        }
    }

    func playSlotMusic() {
        guard !isTransitioningMusic && currentThematicMusic != .slot else { return }
        isTransitioningMusic = true
        
        // Arrêter les autres musiques thématiques (sauf fond qui va fader out)
        splashMusicPlayer?.stop(); splashMusicPlayer?.volume = 0
        boosterOpeningMusicPlayer?.stop(); boosterOpeningMusicPlayer?.volume = 0

        // Action 1: Fondu sortant de la musique de fond
        fadeMusic(player: backgroundMusicPlayer, from: backgroundMusicPlayer?.volume ?? maxMusicVolume, to: 0, duration: fadeDuration) { [weak self] in
            guard let self = self else { return }
            // Action 2: Une fois la musique de fond estompée, fondu entrant de la musique des slots
            // On ne change currentThematicMusic qu'au moment où la nouvelle musique commence vraiment
            if self.currentThematicMusic != .slot { // Eviter de relancer si on a déjà switché rapidement ailleurs
                 self.currentThematicMusic = .slot
                 self.fadeMusic(player: self.slotMusicPlayer, from: 0, to: self.maxMusicVolume, duration: self.fadeDuration) {
                     self.isTransitioningMusic = false
                 }
            } else {
                self.isTransitioningMusic = false
            }
        }
    }

    func stopSlotMusic() {
        guard !isTransitioningMusic else { return }
        isTransitioningMusic = true

        // Action 1: Fondu sortant de la musique des slots
        fadeMusic(player: slotMusicPlayer, from: slotMusicPlayer?.volume ?? maxMusicVolume, to: 0, duration: fadeDuration) { [weak self] in
            guard let self = self else { return }
            // Action 2: Une fois la musique des slots estompée, fondu entrant de la musique de fond
            // Sauf si une autre musique thématique (ex: booster) a été demandée entre-temps
            if self.currentThematicMusic == .slot || self.currentThematicMusic == .none { // On revient au fond si on était sur slot ou si rien n'était censé jouer
                self.currentThematicMusic = .background
                self.fadeMusic(player: self.backgroundMusicPlayer, from: 0, to: self.maxMusicVolume, duration: self.fadeDuration) {
                    self.isTransitioningMusic = false
                }
            } else { // Une autre musique a pris le relai, ne pas démarrer le fond
                 self.isTransitioningMusic = false
            }
        }
    }

    func playBoosterOpeningMusic() {
        guard !isTransitioningMusic && currentThematicMusic != .boosterOpening else { return }
        isTransitioningMusic = true
        
        splashMusicPlayer?.stop(); splashMusicPlayer?.volume = 0
        // Ne pas arrêter slotMusicPlayer ici si on veut qu'il continue pendant l'ouverture du booster (à discuter)
        // Pour l'instant, on le coupe pour simplifier.
        slotMusicPlayer?.stop(); slotMusicPlayer?.volume = 0


        // Action 1: Fondu sortant de la musique de fond (si elle jouait)
        let bgVolume = backgroundMusicPlayer?.volume ?? 0
        fadeMusic(player: backgroundMusicPlayer, from: bgVolume, to: 0, duration: fadeDuration) { [weak self] in
            guard let self = self else { return }
            // Action 2: Une fois la musique de fond estompée, fondu entrant de la musique d'ouverture de booster
            if self.currentThematicMusic != .boosterOpening { // Eviter de relancer si on a déjà switché rapidement ailleurs
                self.currentThematicMusic = .boosterOpening
                self.fadeMusic(player: self.boosterOpeningMusicPlayer, from: 0, to: self.maxMusicVolume, duration: self.fadeDuration) {
                    self.isTransitioningMusic = false
                }
            } else {
                 self.isTransitioningMusic = false
            }
        }
    }

    func stopBoosterOpeningMusic() {
        guard !isTransitioningMusic else { return }
        isTransitioningMusic = true
        
        // Action 1: Fondu sortant de la musique d'ouverture de booster
        fadeMusic(player: boosterOpeningMusicPlayer, from: boosterOpeningMusicPlayer?.volume ?? maxMusicVolume, to: 0, duration: fadeDuration) { [weak self] in
            guard let self = self else { return }
            // Action 2: Une fois la musique du booster estompée, fondu entrant de la musique de fond
            // Sauf si une autre musique thématique (ex: slot) a été demandée entre-temps
            if self.currentThematicMusic == .boosterOpening || self.currentThematicMusic == .none {
                self.currentThematicMusic = .background
                self.fadeMusic(player: self.backgroundMusicPlayer, from: 0, to: self.maxMusicVolume, duration: self.fadeDuration) {
                    self.isTransitioningMusic = false
                }
            } else {
                self.isTransitioningMusic = false
            }
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
        // Utilise un son système au lieu du fichier manquant
        AudioServicesPlaySystemSound(1519) // Son système "click"
    }
    
    func playNextCard() {
        // Utilise un son système au lieu du fichier manquant
        AudioServicesPlaySystemSound(1520) // Son système "click positif"
    }
    
    func playSound(named: String, volume: Float = 0.15) {
        guard let path = Bundle.main.url(forResource: named, withExtension: "mp3") else {
            print("Sound file not found: \(named)")
            return
        }
        
        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: path)
            audioPlayer.volume = volume
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            audioPlayer.play()
            effectPlayers.append(audioPlayer)
        } catch {
            print("Could not play sound: \(error.localizedDescription)")
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Remove the player from the array once it's done playing
        effectPlayers.removeAll { $0 == player }
    }
}

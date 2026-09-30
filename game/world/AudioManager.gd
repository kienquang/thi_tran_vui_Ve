extends Node

# AudioManager singleton to handle ambient sounds and footstep effects.
# Placeholder audio files are referenced; replace the paths with actual assets.

var footstep_player: AudioStreamPlayer = null
var rain_player: AudioStreamPlayer = null
var coffee_player: AudioStreamPlayer = null
var birds_player: AudioStreamPlayer = null
var bgm_player: AudioStreamPlayer = null

var is_bgm_muted: bool = false
var is_sfx_muted: bool = false

func _ready():
    # Initialize AudioStreamPlayers
    footstep_player = AudioStreamPlayer.new()
    if ResourceLoader.exists("res://assets/sfx/footstep.wav"):
        footstep_player.stream = load("res://assets/sfx/footstep.wav")
    footstep_player.volume_db = -5
    add_child(footstep_player)

    rain_player = AudioStreamPlayer.new()
    if ResourceLoader.exists("res://assets/sfx/rain.wav"):
        rain_player.stream = load("res://assets/sfx/rain.wav")
    rain_player.volume_db = -10
    add_child(rain_player)

    coffee_player = AudioStreamPlayer.new()
    if ResourceLoader.exists("res://assets/sfx/coffee_pour.wav"):
        coffee_player.stream = load("res://assets/sfx/coffee_pour.wav")
    coffee_player.volume_db = -8
    add_child(coffee_player)

    birds_player = AudioStreamPlayer.new()
    if ResourceLoader.exists("res://assets/sfx/birds.wav"):
        birds_player.stream = load("res://assets/sfx/birds.wav")
    birds_player.volume_db = -8
    add_child(birds_player)
    
    bgm_player = AudioStreamPlayer.new()
    if ResourceLoader.exists("res://assets/sfx/bgm.ogg"):
        bgm_player.stream = load("res://assets/sfx/bgm.ogg")
    elif ResourceLoader.exists("res://assets/sfx/bgm.wav"):
        bgm_player.stream = load("res://assets/sfx/bgm.wav")
    elif ResourceLoader.exists("res://assets/sfx/bgm.mp3"):
        bgm_player.stream = load("res://assets/sfx/bgm.mp3")
    bgm_player.volume_db = -12
    add_child(bgm_player)
    if not is_bgm_muted:
        play_bgm()

func toggle_bgm():
    is_bgm_muted = not is_bgm_muted
    if is_bgm_muted:
        bgm_player.stop()
    else:
        play_bgm()
        
func toggle_sfx():
    is_sfx_muted = not is_sfx_muted
    if is_sfx_muted:
        stop_footstep()
        stop_rain()
        stop_birds()
    else:
        # Let the ambient loops recover via TimeManager/weather state if needed
        pass

func play_bgm():
    if bgm_player and bgm_player.stream != null and not is_bgm_muted and not bgm_player.playing:
        bgm_player.play()

# Footstep sound, called from player movement logic.
func play_footstep():
    if is_sfx_muted: return
    if footstep_player and footstep_player.stream != null and not footstep_player.playing:
        footstep_player.play()

func stop_footstep():
    if footstep_player and footstep_player.playing:
        footstep_player.stop()

# Rain ambient sound.
func play_rain():
    if is_sfx_muted: return
    if rain_player and rain_player.stream != null and not rain_player.playing:
        rain_player.play()

func stop_rain():
    if rain_player and rain_player.playing:
        rain_player.stop()

# Coffee sound, e.g., when buying coffee.
func play_coffee():
    if is_sfx_muted: return
    if coffee_player and coffee_player.stream != null:
        coffee_player.play()

# Birds chirping sound for sunny weather.
func play_birds():
    if is_sfx_muted: return
    if birds_player and birds_player.stream != null and not birds_player.playing:
        birds_player.play()

func stop_birds():
    if birds_player and birds_player.playing:
        birds_player.stop()

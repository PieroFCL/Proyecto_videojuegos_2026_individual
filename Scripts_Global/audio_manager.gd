extends Node

# Reproductores
var music_menu: AudioStreamPlayer
var music_ambient: AudioStreamPlayer
var music_combat: AudioStreamPlayer
var music_boss: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

# Rutas (ajustar según tus nombres de archivo)
const MENU_MUSIC = "res://Audio/Music/main_menu.mp3"
const AMBIENT_MUSIC = "res://Audio/Music/ambient.mp3"
const COMBAT_BASIC_MUSIC = "res://Audio/Music/combat_basic.mp3"
const COMBAT_BOSS_MUSIC = "res://Audio/Music/combat_boss.mp3"
const UI_SFX = "res://Audio/SFX/action.mp3"

func _ready():
	# Crear nodos
	music_menu = AudioStreamPlayer.new()
	music_ambient = AudioStreamPlayer.new()
	music_combat = AudioStreamPlayer.new()
	music_boss = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	
	music_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	music_ambient.process_mode = Node.PROCESS_MODE_ALWAYS
	music_combat.process_mode = Node.PROCESS_MODE_ALWAYS
	music_boss.process_mode = Node.PROCESS_MODE_ALWAYS
	# sfx_player también si quieres que el sonido de teclas funcione durante la pausa
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	add_child(music_menu)
	add_child(music_ambient)
	add_child(music_combat)
	add_child(music_boss)
	add_child(sfx_player)
	
	# Cargar streams (con comprobación)
	music_menu.stream = load(MENU_MUSIC) if ResourceLoader.exists(MENU_MUSIC) else null
	music_ambient.stream = load(AMBIENT_MUSIC) if ResourceLoader.exists(AMBIENT_MUSIC) else null
	music_combat.stream = load(COMBAT_BASIC_MUSIC) if ResourceLoader.exists(COMBAT_BASIC_MUSIC) else null
	music_boss.stream = load(COMBAT_BOSS_MUSIC) if ResourceLoader.exists(COMBAT_BOSS_MUSIC) else null
	sfx_player.stream = load(UI_SFX) if ResourceLoader.exists(UI_SFX) else null
	
	# Volumen por defecto (opcional)
	music_menu.volume_db = -10
	music_ambient.volume_db = -12
	music_combat.volume_db = -8
	music_boss.volume_db = -6
	sfx_player.volume_db = -5

func _stop_all_music():
	music_menu.stop()
	music_ambient.stop()
	music_combat.stop()
	music_boss.stop()

func play_menu_music():
	_stop_all_music()
	if music_menu.stream: music_menu.play()

func play_ambient_music():
	_stop_all_music()
	if music_ambient.stream: music_ambient.play()

func play_combat_music():
	_stop_all_music()
	if music_combat.stream: music_combat.play()

func play_boss_music():
	_stop_all_music()
	if music_boss.stream: music_boss.play()

func play_ui_sfx():
	if sfx_player.stream:
		sfx_player.stop()
		sfx_player.play()

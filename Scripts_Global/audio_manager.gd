extends Node
# Gestor central de música y efectos de sonido.

# Reproductor de música del menú principal.
var music_menu: AudioStreamPlayer
# Reproductor de música ambiente del mundo.
var music_ambient: AudioStreamPlayer
# Reproductor de música de combate normal.
var music_combat: AudioStreamPlayer
# Reproductor de música de combate contra jefes.
var music_boss: AudioStreamPlayer
# Reproductor de efectos de sonido (UI, teclas).
var sfx_player: AudioStreamPlayer

# Ruta del archivo de música del menú.
const MENU_MUSIC = "res://Audio/Music/main_menu.mp3"
# Ruta del archivo de música ambiente.
const AMBIENT_MUSIC = "res://Audio/Music/ambient.mp3"
# Ruta del archivo de música de combate básico.
const COMBAT_BASIC_MUSIC = "res://Audio/Music/combat_basic.mp3"
# Ruta del archivo de música de combate contra jefes.
const COMBAT_BOSS_MUSIC = "res://Audio/Music/combat_boss.mp3"
# Ruta del archivo de efecto de sonido UI.
const UI_SFX = "res://Audio/SFX/action.mp3"

# Crea y configura los reproductores de audio.
func _ready():
	# Crea los nodos internos.
	music_menu = AudioStreamPlayer.new()
	music_ambient = AudioStreamPlayer.new()
	music_combat = AudioStreamPlayer.new()
	music_boss = AudioStreamPlayer.new()
	sfx_player = AudioStreamPlayer.new()
	
	# Permite que la música suene incluso con juego pausado.
	music_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	music_ambient.process_mode = Node.PROCESS_MODE_ALWAYS
	music_combat.process_mode = Node.PROCESS_MODE_ALWAYS
	music_boss.process_mode = Node.PROCESS_MODE_ALWAYS
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Añade los nodos al árbol.
	add_child(music_menu)
	add_child(music_ambient)
	add_child(music_combat)
	add_child(music_boss)
	add_child(sfx_player)
	
	# Carga los streams de audio si existen.
	music_menu.stream = load(MENU_MUSIC) if ResourceLoader.exists(MENU_MUSIC) else null
	music_ambient.stream = load(AMBIENT_MUSIC) if ResourceLoader.exists(AMBIENT_MUSIC) else null
	music_combat.stream = load(COMBAT_BASIC_MUSIC) if ResourceLoader.exists(COMBAT_BASIC_MUSIC) else null
	music_boss.stream = load(COMBAT_BOSS_MUSIC) if ResourceLoader.exists(COMBAT_BOSS_MUSIC) else null
	sfx_player.stream = load(UI_SFX) if ResourceLoader.exists(UI_SFX) else null
	
	# Ajusta volúmenes iniciales (valores en decibelios).
	music_menu.volume_db = -10
	music_ambient.volume_db = -12
	music_combat.volume_db = -8
	music_boss.volume_db = -6
	sfx_player.volume_db = -5

# Detiene toda la música actual.
func _stop_all_music():
	music_menu.stop()
	music_ambient.stop()
	music_combat.stop()
	music_boss.stop()

# Reproduce la música del menú principal.
func play_menu_music():
	_stop_all_music()
	if music_menu.stream: music_menu.play()

# Reproduce la música ambiente del mundo.
func play_ambient_music():
	_stop_all_music()
	if music_ambient.stream: music_ambient.play()

# Reproduce la música de combate normal.
func play_combat_music():
	_stop_all_music()
	if music_combat.stream: music_combat.play()

# Reproduce la música de combate contra jefes.
func play_boss_music():
	_stop_all_music()
	if music_boss.stream: music_boss.play()

# Reproduce el efecto de sonido de interfaz.
func play_ui_sfx():
	if sfx_player.stream:
		sfx_player.stop()
		sfx_player.play()

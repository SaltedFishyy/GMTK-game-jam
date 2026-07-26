extends AudioStreamPlayer

const LOBBY_SCENE_PATHS: Array[String] = [
	"res://scenes/StartingPage.tscn",
	"res://scenes/IntroStory.tscn",
]
const IN_GAME_SCENE_PATHS: Array[String] = [
	"res://day_start.tscn",
	"res://scenes/toilet.tscn",
	"res://scenes/end_day.tscn",
	"res://scenes/shop.tscn",
]

var lobby_bgm: AudioStreamWAV = preload("res://scenes/resources/music/bgm/Lobby BGM.wav")
var in_game_bgm: AudioStreamWAV = preload("res://scenes/resources/music/bgm/In game BGM.wav")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bus = &"Music"
	lobby_bgm.loop_mode = AudioStreamWAV.LOOP_FORWARD
	in_game_bgm.loop_mode = AudioStreamWAV.LOOP_FORWARD
	get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_sync_with_current_scene")


func ensure_lobby_music() -> void:
	_ensure_music(lobby_bgm)


func ensure_in_game_music() -> void:
	_ensure_music(in_game_bgm)


func stop_music() -> void:
	if playing:
		stop()


func _on_scene_changed(_new_scene: Node) -> void:
	_sync_with_current_scene()


func _sync_with_current_scene() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene != null and current_scene.scene_file_path in LOBBY_SCENE_PATHS:
		ensure_lobby_music()
	elif current_scene != null and current_scene.scene_file_path in IN_GAME_SCENE_PATHS:
		ensure_in_game_music()
	else:
		stop_music()


func _ensure_music(desired_stream: AudioStreamWAV) -> void:
	if playing and stream == desired_stream:
		return
	stream = desired_stream
	play()

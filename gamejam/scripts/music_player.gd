extends AudioStreamPlayer

var lobby_scene_paths: Array[String] = [
	GameState.STARTING_PAGE_SCENE_PATH,
	GameState.INTRO_STORY_SCENE_PATH,
]
var in_game_scene_paths: Array[String] = [
	GameState.DAY_START_SCENE_PATH,
	GameState.TOILET_SCENE_PATH,
	GameState.END_DAY_SCENE_PATH,
	GameState.SHOP_SCENE_PATH,
]

var lobby_bgm: AudioStreamWAV = preload("res://scenes/resources/music/bgm/Lobby BGM.wav")
var in_game_bgm: AudioStreamWAV = preload("res://scenes/resources/music/bgm/In game BGM.wav")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bus = &"Music"
	_configure_looping_stream(lobby_bgm)
	_configure_looping_stream(in_game_bgm)
	get_tree().scene_changed.connect(_on_scene_changed)
	call_deferred("_sync_with_current_scene")


func ensure_lobby_music() -> void:
	_ensure_music(lobby_bgm)


func ensure_in_game_music() -> void:
	_ensure_music(in_game_bgm)


func stop_music() -> void:
	if playing:
		stop()


func _on_scene_changed() -> void:
	_sync_with_current_scene()


func _sync_with_current_scene() -> void:
	var current_scene: Node = get_tree().current_scene
	if current_scene != null and current_scene.scene_file_path in lobby_scene_paths:
		ensure_lobby_music()
	elif current_scene != null and current_scene.scene_file_path in in_game_scene_paths:
		ensure_in_game_music()
	else:
		stop_music()


func _ensure_music(desired_stream: AudioStreamWAV) -> void:
	if playing and stream == desired_stream:
		return
	stream = desired_stream
	play()


func _configure_looping_stream(audio_stream: AudioStreamWAV) -> void:
	audio_stream.loop_begin = 0
	audio_stream.loop_end = maxi(
		roundi(audio_stream.get_length() * float(audio_stream.mix_rate)), 1
	)
	audio_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD

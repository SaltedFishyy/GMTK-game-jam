class_name PauseMenu
extends CanvasLayer

const MUSIC_BUS_NAME: StringName = &"Music"
const NORMAL_RESUME_RESTART_TEXTURE: Texture2D = preload(
	"res://scenes/resources/Menu/resume_restart.png"
)
const RESUME_PRESSED_TEXTURE: Texture2D = preload(
	"res://scenes/resources/Menu/resume_pressed.png"
)
const RESTART_PRESSED_TEXTURE: Texture2D = preload(
	"res://scenes/resources/Menu/restart_pressed.png"
)
const TRACK_START_X: float = 20.0
const TRACK_WIDTH: float = 144.0
const TRACK_HEIGHT: float = 20.0
const RIGHT_CAP_WIDTH: float = 16.0
const HANDLE_WIDTH: float = 41.0

var has_paused_tree: bool = false
var is_dragging_music: bool = false
var music_volume_ratio: float = 1.0
var has_warned_missing_music_bus: bool = false

@onready var menu_button: TextureButton = $MenuButton
@onready var input_blocker: ColorRect = $InputBlocker
@onready var menu_overlay: Control = $MenuOverlay
@onready var home_button: TextureButton = $MenuOverlay/HomeButton
@onready var state_texture: TextureRect = $MenuOverlay/ResumeRestartControl/StateTexture
@onready var resume_hitbox: Button = $MenuOverlay/ResumeRestartControl/ResumeHitbox
@onready var restart_hitbox: Button = $MenuOverlay/ResumeRestartControl/RestartHitbox
@onready var music_slider: Control = $MenuOverlay/MusicSlider
@onready var on_fill_clip: Control = $MenuOverlay/MusicSlider/OnFillClip
@onready var fill_right_cap: TextureRect = $MenuOverlay/MusicSlider/FillRightCap
@onready var handle: TextureRect = $MenuOverlay/MusicSlider/Handle


func _ready() -> void:
	get_tree().paused = false
	has_paused_tree = false
	is_dragging_music = false
	_set_menu_visible(false)
	_set_action_buttons_disabled(false)
	_set_resume_restart_texture(NORMAL_RESUME_RESTART_TEXTURE)
	_sync_music_volume_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not mouse_event.pressed:
			is_dragging_music = false

	if not event.is_action_pressed("ui_cancel"):
		return
	if event is InputEventKey and event.echo:
		return

	get_viewport().set_input_as_handled()
	toggle_pause()


func toggle_pause() -> void:
	if has_paused_tree:
		resume_game()
	else:
		pause_game()


func pause_game() -> void:
	if has_paused_tree:
		return

	has_paused_tree = true
	is_dragging_music = false
	_set_action_buttons_disabled(false)
	_set_resume_restart_texture(NORMAL_RESUME_RESTART_TEXTURE)
	_sync_music_volume_ui()
	_set_menu_visible(true)
	get_tree().paused = true


func resume_game() -> void:
	is_dragging_music = false
	get_tree().paused = false
	has_paused_tree = false
	_set_menu_visible(false)
	_set_action_buttons_disabled(false)
	_set_resume_restart_texture(NORMAL_RESUME_RESTART_TEXTURE)


func _set_menu_visible(should_show: bool) -> void:
	menu_overlay.visible = should_show
	input_blocker.visible = should_show
	input_blocker.mouse_filter = (
		Control.MOUSE_FILTER_STOP if should_show else Control.MOUSE_FILTER_IGNORE
	)
	menu_button.visible = not should_show
	menu_button.disabled = should_show


func _set_action_buttons_disabled(should_disable: bool) -> void:
	home_button.disabled = should_disable
	resume_hitbox.disabled = should_disable
	restart_hitbox.disabled = should_disable


func _set_resume_restart_texture(texture: Texture2D) -> void:
	state_texture.texture = texture


func _sync_music_volume_ui() -> void:
	var music_bus_index: int = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if music_bus_index < 0:
		_warn_missing_music_bus()
		_update_music_visual()
		return

	if AudioServer.is_bus_mute(music_bus_index):
		music_volume_ratio = 0.0
	else:
		music_volume_ratio = clampf(
			db_to_linear(AudioServer.get_bus_volume_db(music_bus_index)),
			0.0,
			1.0
		)
	_update_music_visual()


func _set_music_volume_ratio(value: float, apply_to_audio: bool = true) -> void:
	music_volume_ratio = clampf(value, 0.0, 1.0)
	_update_music_visual()
	if apply_to_audio:
		_apply_music_volume()


func _apply_music_volume() -> void:
	var music_bus_index: int = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if music_bus_index < 0:
		_warn_missing_music_bus()
		return

	if is_zero_approx(music_volume_ratio):
		AudioServer.set_bus_mute(music_bus_index, true)
		return

	AudioServer.set_bus_mute(music_bus_index, false)
	AudioServer.set_bus_volume_db(
		music_bus_index,
		linear_to_db(music_volume_ratio)
	)


func _warn_missing_music_bus() -> void:
	if has_warned_missing_music_bus:
		return
	has_warned_missing_music_bus = true
	push_warning("PauseMenu could not find the Music audio bus.")


func _update_music_visual() -> void:
	var boundary_x: float = TRACK_START_X + TRACK_WIDTH * music_volume_ratio
	on_fill_clip.size = Vector2(TRACK_WIDTH * music_volume_ratio, TRACK_HEIGHT)
	fill_right_cap.position.x = boundary_x - RIGHT_CAP_WIDTH * 0.5
	handle.position.x = boundary_x - HANDLE_WIDTH * 0.5


func _update_music_from_local_x(local_x: float) -> void:
	_set_music_volume_ratio((local_x - TRACK_START_X) / TRACK_WIDTH)


func _on_menu_button_pressed() -> void:
	pause_game()


func _on_home_button_pressed() -> void:
	_set_action_buttons_disabled(true)
	is_dragging_music = false
	GameState.return_to_starting_page()


func _on_resume_hitbox_button_down() -> void:
	_set_resume_restart_texture(RESUME_PRESSED_TEXTURE)


func _on_resume_hitbox_button_up() -> void:
	_set_resume_restart_texture(NORMAL_RESUME_RESTART_TEXTURE)


func _on_resume_hitbox_mouse_exited() -> void:
	_set_resume_restart_texture(NORMAL_RESUME_RESTART_TEXTURE)


func _on_resume_hitbox_pressed() -> void:
	resume_game()


func _on_restart_hitbox_button_down() -> void:
	_set_resume_restart_texture(RESTART_PRESSED_TEXTURE)


func _on_restart_hitbox_button_up() -> void:
	_set_resume_restart_texture(NORMAL_RESUME_RESTART_TEXTURE)


func _on_restart_hitbox_mouse_exited() -> void:
	_set_resume_restart_texture(NORMAL_RESUME_RESTART_TEXTURE)


func _on_restart_hitbox_pressed() -> void:
	_set_action_buttons_disabled(true)
	is_dragging_music = false
	GameState.restart_run()


func _on_music_slider_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		is_dragging_music = mouse_event.pressed
		if mouse_event.pressed:
			_update_music_from_local_x(mouse_event.position.x)
		music_slider.accept_event()
		return

	if event is InputEventMouseMotion and is_dragging_music:
		var motion_event: InputEventMouseMotion = event
		_update_music_from_local_x(motion_event.position.x)
		music_slider.accept_event()


func _exit_tree() -> void:
	is_dragging_music = false
	if has_paused_tree:
		get_tree().paused = false
		has_paused_tree = false

class_name PauseMenu
extends CanvasLayer

const MUSIC_BUS_NAME: StringName = &"Music"

@onready var menu_root: Control = $MenuRoot
@onready var menu_button: Button = $MenuButton
@onready var pause_panel: Panel = $MenuRoot/PausePanel
@onready var options_panel: Panel = $MenuRoot/OptionsPanel
@onready var restart_confirmation_panel: Panel = $MenuRoot/RestartConfirmationPanel
@onready var music_volume_slider: HSlider = $MenuRoot/OptionsPanel/MusicVolumeSlider
@onready var music_percent_label: Label = $MenuRoot/OptionsPanel/MusicPercentLabel

var has_paused_tree: bool = false


# 初始化菜单页面，并从Music总线同步当前音量。
func _ready() -> void:
	menu_root.hide()
	menu_button.show()
	_show_pause_panel()
	_sync_music_volume_ui()


# 使用现有ui_cancel动作处理暂停、恢复和设置页返回。
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if event is InputEventKey and event.echo:
		return

	get_viewport().set_input_as_handled()
	if (
		has_paused_tree
		and (
			options_panel.visible
			or restart_confirmation_panel.visible
		)
	):
		_show_pause_panel()
	else:
		toggle_pause()


# 在暂停和继续之间切换。
func toggle_pause() -> void:
	if has_paused_tree:
		resume_game()
	else:
		pause_game()


# 显示菜单并暂停默认游戏逻辑。
func pause_game() -> void:
	if has_paused_tree:
		return

	has_paused_tree = true
	_show_pause_panel()
	menu_button.hide()
	menu_root.show()
	get_tree().paused = true


# 隐藏菜单并从原状态继续游戏。
func resume_game() -> void:
	if not has_paused_tree:
		menu_root.hide()
		menu_button.show()
		_show_pause_panel()
		return

	get_tree().paused = false
	has_paused_tree = false
	menu_root.hide()
	menu_button.show()
	_show_pause_panel()


# 显示暂停主页并隐藏设置页面。
func _show_pause_panel() -> void:
	pause_panel.show()
	options_panel.hide()
	restart_confirmation_panel.hide()


# 显示音乐设置页面，游戏继续保持暂停。
func _show_options_panel() -> void:
	pause_panel.hide()
	options_panel.show()
	restart_confirmation_panel.hide()


# 显示重新开始确认页，并保持游戏暂停。
func _show_restart_confirmation() -> void:
	pause_panel.hide()
	options_panel.hide()
	restart_confirmation_panel.show()


# 从Music总线读取当前状态，避免切换场景时重置音量。
func _sync_music_volume_ui() -> void:
	var music_bus_index: int = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if music_bus_index < 0:
		music_volume_slider.editable = false
		music_percent_label.text = "100%"
		return

	music_volume_slider.editable = true
	var volume_percent: float = 0.0
	if not AudioServer.is_bus_mute(music_bus_index):
		var linear_volume: float = db_to_linear(
			AudioServer.get_bus_volume_db(music_bus_index)
		)
		volume_percent = clampf(linear_volume * 100.0, 0.0, 100.0)

	music_volume_slider.set_value_no_signal(volume_percent)
	_update_music_percent_label(volume_percent)


# 将滑动条数值安全应用到独立Music总线。
func _apply_music_volume(volume_percent: float) -> void:
	var music_bus_index: int = AudioServer.get_bus_index(MUSIC_BUS_NAME)
	if music_bus_index < 0:
		return

	var safe_volume: float = clampf(volume_percent, 0.0, 100.0)
	if is_zero_approx(safe_volume):
		AudioServer.set_bus_mute(music_bus_index, true)
		return

	AudioServer.set_bus_mute(music_bus_index, false)
	AudioServer.set_bus_volume_db(
		music_bus_index,
		linear_to_db(safe_volume / 100.0)
	)


# 更新音乐音量的整数百分比文字。
func _update_music_percent_label(volume_percent: float) -> void:
	music_percent_label.text = "%d%%" % roundi(volume_percent)


# 点击右上角MENU按钮时打开暂停主页。
func _on_menu_button_pressed() -> void:
	pause_game()


# 点击RESUME按钮时使用同一个恢复入口。
func _on_resume_button_pressed() -> void:
	resume_game()


# 点击OPTIONS按钮时进入设置页面。
func _on_options_button_pressed() -> void:
	_show_options_panel()


# 点击RESTART RUN时只打开确认页，不修改本局状态。
func _on_restart_run_button_pressed() -> void:
	_show_restart_confirmation()


# 点击BACK按钮时返回暂停主页。
func _on_back_button_pressed() -> void:
	_show_pause_panel()


# 点击CANCEL时返回暂停主页，不修改任何状态。
func _on_restart_cancel_button_pressed() -> void:
	_show_pause_panel()


# 确认重新开始时只调用GameState的统一协调入口。
func _on_restart_confirm_button_pressed() -> void:
	GameState.restart_run()


# 滑动条改变时实时更新Music总线和百分比。
func _on_music_volume_slider_value_changed(value: float) -> void:
	_update_music_percent_label(value)
	_apply_music_volume(value)


# 如果暂停菜单随场景离开，确保SceneTree不会残留暂停状态。
func _exit_tree() -> void:
	if has_paused_tree:
		get_tree().paused = false
		has_paused_tree = false

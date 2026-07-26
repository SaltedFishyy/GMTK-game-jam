extends Control

@export_range(0.0, 10.0, 0.1, "suffix:s") var continue_delay: float = 3.0

var can_continue: bool = false
var has_advanced_to_second_page: bool = false
var is_returning_home: bool = false

@onready var first_page: Control = $FirstPage
@onready var first_page_click_catcher: Button = $FirstPage/FirstPageClickCatcher
@onready var second_page: Control = $SecondPage
@onready var return_in_glory_button: TextureButton = (
	$SecondPage/ReturnInGloryButton
)


# 胜利场景始终从第一张整页画面开始，返回按钮等待第二阶段再启用。
func _ready() -> void:
	get_tree().paused = false
	first_page.show()
	second_page.hide()
	can_continue = false
	first_page_click_catcher.disabled = true
	return_in_glory_button.disabled = true
	_unlock_first_page_after_delay()


func _unlock_first_page_after_delay() -> void:
	await get_tree().create_timer(maxf(continue_delay, 0.0)).timeout
	if not is_inside_tree() or has_advanced_to_second_page:
		return
	can_continue = true
	first_page_click_catcher.disabled = false


# 第一次全屏点击只切换页面，并消费本次输入，避免穿透到返回按钮。
func _on_first_page_click_catcher_pressed() -> void:
	if not can_continue or has_advanced_to_second_page:
		return

	can_continue = false
	has_advanced_to_second_page = true
	first_page_click_catcher.disabled = true
	first_page.hide()
	second_page.show()
	await get_tree().process_frame
	if is_inside_tree() and not is_returning_home:
		return_in_glory_button.disabled = false


# 清空本局数据但保留Music总线设置，然后返回正式StartingPage。
func _on_return_in_glory_button_pressed() -> void:
	if is_returning_home:
		return

	is_returning_home = true
	return_in_glory_button.disabled = true
	get_tree().paused = false
	GameState.reset_run_progress()
	var scene_change_error: Error = get_tree().change_scene_to_file(
		GameState.STARTING_PAGE_SCENE_PATH
	)
	if scene_change_error == OK:
		return

	is_returning_home = false
	return_in_glory_button.disabled = false
	push_error(
		"Failed to return from Win Scene: %s" % error_string(scene_change_error)
	)

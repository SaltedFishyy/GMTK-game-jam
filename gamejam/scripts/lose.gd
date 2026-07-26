extends Control

@export_range(0.0, 10.0, 0.1, "suffix:s") var continue_delay: float = 3.0

var can_continue: bool = false
var has_advanced_to_second_page: bool = false
var is_returning_home: bool = false

@onready var first_page: Control = $FirstPage
@onready var first_page_click_catcher: Button = $FirstPage/FirstPageClickCatcher
@onready var second_page: Control = $SecondPage
@onready var stink_away_button: TextureButton = $SecondPage/StinkAwayButton


# 失败场景始终从第一张整页画面开始，第二页按钮等待切页后再启用。
func _ready() -> void:
	get_tree().paused = false
	first_page.show()
	second_page.hide()
	can_continue = false
	first_page_click_catcher.disabled = true
	stink_away_button.disabled = true
	_unlock_first_page_after_delay()


func _unlock_first_page_after_delay() -> void:
	await get_tree().create_timer(maxf(continue_delay, 0.0)).timeout
	if not is_inside_tree() or has_advanced_to_second_page:
		return
	can_continue = true
	first_page_click_catcher.disabled = false


# 第一次全屏点击只切换页面，下一帧才允许返回按钮接收输入。
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
		stink_away_button.disabled = false


# 复用GameState Home入口清空本局并返回StartingPage，Music总线不参与重置。
func _on_stink_away_button_pressed() -> void:
	if is_returning_home:
		return

	is_returning_home = true
	stink_away_button.disabled = true
	get_tree().paused = false
	GameState.return_to_starting_page()

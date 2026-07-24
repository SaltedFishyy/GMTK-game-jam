extends Control

const TOILET_SCENE_PATH: String = "res://scenes/toilet.tscn"

@onready var total_money_label: Label = $TotalMoneyLabel
@onready var next_day_button: Button = $NextDayButton

var has_advanced_day: bool = false


# 进入商店时显示当前游戏进程中累计的总金钱。
func _ready() -> void:
	total_money_label.text = "Total Money: $%d" % Economy.total_money
	next_day_button.disabled = GameState.is_final_day()


# 点击 NEXT DAY 后只推进一次天数，并返回厕所开始新一轮。
func _on_next_day_button_pressed() -> void:
	if has_advanced_day or GameState.is_final_day():
		return

	has_advanced_day = true
	next_day_button.disabled = true
	GameState.advance_day()
	get_tree().change_scene_to_file(TOILET_SCENE_PATH)

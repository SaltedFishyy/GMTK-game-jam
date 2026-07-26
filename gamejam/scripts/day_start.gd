class_name DayStart
extends Node2D

const FoodDefinitionsScript = preload("res://scripts/food/food_definitions.gd")

@onready var days_remaining_label: Label = %DaysRemainingLabel
@onready var large_intestine_level_label: Label = %LargeIntestineLevelLabel
@onready var large_intestine_value_label: Label = %LargeIntestineValueLabel
@onready var sphincter_level_label: Label = %SphincterLevelLabel
@onready var sphincter_value_label: Label = %SphincterValueLabel
@onready var abdominal_level_label: Label = %AbdominalLevelLabel
@onready var abdominal_value_label: Label = %AbdominalValueLabel
@onready var food_container: HBoxContainer = %FoodContainer
@onready var continue_button: Button = %ContinueButton


# 进入每日开始页面时，从现有跨场景数据刷新一次全部显示。
func _ready() -> void:
	_update_day_label()
	_update_organ_panels()
	_update_active_foods()
	continue_button.disabled = false


# 根据当前天数显示剩余天数，并正确处理单复数。
func _update_day_label() -> void:
	var remaining_days: int = maxi(GameState.MAX_DAYS - GameState.current_day + 1, 1)
	var day_word: String = "DAY" if remaining_days == 1 else "DAYS"
	days_remaining_label.text = "%d %s" % [remaining_days, day_word]


# 读取现有器官与玩家属性接口，更新三个厕所玩法器官面板。
func _update_organ_panels() -> void:
	large_intestine_level_label.text = (
		"LV. %d / %d"
		% [
			OrganProgression.get_level(OrganProgression.Organ.LARGE_INTESTINE),
			OrganProgression.MAX_LEVEL,
		]
	)
	large_intestine_value_label.text = (
		"STORAGE: %d / %d"
		% [
			PlayerStats.get_effective_storage_capacity(),
			PlayerStats.MAX_STAT_VALUE,
		]
	)

	sphincter_level_label.text = (
		"LV. %d / %d"
		% [
			OrganProgression.get_level(OrganProgression.Organ.SPHINCTER),
			OrganProgression.MAX_LEVEL,
		]
	)
	var sphincter_bonus_percent: int = roundi(
		(OrganProgression.get_sphincter_qte_width_multiplier() - 1.0) * 100.0
	)
	sphincter_value_label.text = "QTE WIDTH: +%d%%" % sphincter_bonus_percent

	abdominal_level_label.text = (
		"LV. %d / %d"
		% [
			OrganProgression.get_level(OrganProgression.Organ.ABDOMINAL_MUSCLES),
			OrganProgression.MAX_LEVEL,
		]
	)
	var abdominal_bonus_percent: int = roundi(
		(OrganProgression.get_abdominal_push_multiplier() - 1.0) * 100.0
	)
	abdominal_value_label.text = "CHARGED PUSH: +%d%%" % abdominal_bonus_percent


# 按当前生效食物数组顺序创建图标；没有食物时保持容器为空。
func _update_active_foods() -> void:
	for food_id: int in FoodSystem.get_active_food_ids():
		var definition: Dictionary = FoodDefinitionsScript.get_food(food_id)
		if definition.is_empty():
			continue
		food_container.add_child(_create_food_display(definition))


# 为一份当天食物创建只负责显示的图标与名称。
func _create_food_display(definition: Dictionary) -> VBoxContainer:
	var food_display := VBoxContainer.new()
	food_display.custom_minimum_size = Vector2(88.0, 84.0)
	food_display.alignment = BoxContainer.ALIGNMENT_CENTER

	var food_icon := TextureRect.new()
	food_icon.custom_minimum_size = Vector2(56.0, 56.0)
	food_icon.texture = definition["icon"] as Texture2D
	food_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	food_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	food_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	food_display.add_child(food_icon)

	var food_name := Label.new()
	food_name.text = String(definition["display_name"])
	food_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	food_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	food_display.add_child(food_name)
	return food_display


# 点击CONTINUE后进入现有厕所场景。
func _on_continue_button_pressed() -> void:
	continue_button.disabled = true
	var scene_change_error: Error = get_tree().change_scene_to_file(GameState.TOILET_SCENE_PATH)
	if scene_change_error == OK:
		return

	push_error(
		(
			"Failed to continue day: could not load %s (error %d)."
			% [GameState.TOILET_SCENE_PATH, scene_change_error]
		)
	)
	continue_button.disabled = false

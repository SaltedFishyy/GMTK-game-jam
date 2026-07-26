class_name DayStart
extends Control

const FoodDefinitionsScript = preload("res://scripts/food/food_definitions.gd")
const PoopReserveScript = preload("res://scripts/poop_reserve.gd")
const ToiletScript = preload("res://scripts/toilet.gd")
const CENTIMETERS_PER_FOOT: float = 30.48
const DAY_BACKGROUND_TEXTURES: Array[Texture2D] = [
	preload("res://scenes/resources/StartingPage/Days/5days.png"),
	preload("res://scenes/resources/StartingPage/Days/4days.png"),
	preload("res://scenes/resources/StartingPage/Days/3days.png"),
	preload("res://scenes/resources/StartingPage/Days/2days.png"),
	preload("res://scenes/resources/StartingPage/Days/1days.png"),
]

@onready var day_background: TextureRect = %DayBackground
@onready var large_intestine_effect_value_label: Label = %LargeIntestineEffectValueLabel
@onready var large_intestine_effect_description_label: Label = (
	%LargeIntestineEffectDescriptionLabel
)
@onready var sphincter_effect_value_label: Label = %SphincterEffectValueLabel
@onready var sphincter_effect_description_label: Label = %SphincterEffectDescriptionLabel
@onready var abdominal_effect_value_label: Label = %AbdominalEffectValueLabel
@onready var abdominal_effect_description_label: Label = %AbdominalEffectDescriptionLabel
@onready var food_container: HBoxContainer = %FoodContainer
@onready var continue_button: Button = %ContinueButton


# 进入每日开始页面时，从现有跨场景数据刷新一次全部显示。
func _ready() -> void:
	_update_day_background()
	_update_organ_panels()
	_update_active_foods()
	continue_button.disabled = false


# 根据当前天数切换唯一的整页背景，并安全处理意外的越界值。
func _update_day_background() -> void:
	var safe_day: int = clampi(GameState.current_day, 1, GameState.MAX_DAYS)
	day_background.texture = DAY_BACKGROUND_TEXTURES[safe_day - 1]


# 读取现有器官与玩家属性接口，更新三个厕所玩法器官面板。
func _update_organ_panels() -> void:
	var base_storage_cm: float = PoopReserveScript.get_max_reserve_cm_for_capacity(
		PlayerStats.get_storage_capacity()
	) + OrganProgression.get_large_intestine_storage_bonus_cm()
	large_intestine_effect_value_label.text = _format_length_with_food_bonus(
		base_storage_cm,
		FoodSystem.get_active_storage_bonus()
	)
	large_intestine_effect_description_label.text = "OF POOP STORED"

	sphincter_effect_value_label.text = OrganProgression.get_sphincter_risk_state()
	sphincter_effect_description_label.text = "BREAK RISK"

	abdominal_effect_value_label.text = _format_length_with_food_bonus(
		ToiletScript.get_max_charged_push_distance_cm_without_food(),
		FoodSystem.get_active_charge_bonus()
	)
	abdominal_effect_description_label.text = "PER FULL CHARGE"


# 将厘米向下截断到一位小数的英尺显示，并附加食物原始加成点数。
func _format_length_with_food_bonus(length_cm: float, food_bonus: int) -> String:
	var feet_tenths: int = floori(maxf(length_cm, 0.0) / CENTIMETERS_PER_FOOT * 10.0)
	var feet_text: String
	if feet_tenths % 10 == 0:
		feet_text = str(feet_tenths / 10)
	else:
		feet_text = "%.1f" % (float(feet_tenths) / 10.0)

	var result: String = "%s FT" % feet_text
	if food_bonus != 0:
		result += " (%+d)" % food_bonus
	return result


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

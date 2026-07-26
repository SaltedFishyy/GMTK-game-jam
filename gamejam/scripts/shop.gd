extends Control

const ToiletScript = preload("res://scripts/toilet.gd")
const CENTIMETERS_PER_FOOT: float = 30.48

var has_advanced_day: bool = false
var is_processing_organ_purchase: bool = false

@onready var total_money_label: Label = %TotalMoneyLabel
@onready var large_intestine_effect_value_label: Label = %LargeIntestineEffectValueLabel
@onready var large_intestine_effect_description_label: Label = %LargeIntestineEffectDescriptionLabel
@onready var abdominal_effect_value_label: Label = %AbdominalEffectValueLabel
@onready var abdominal_effect_description_label: Label = %AbdominalEffectDescriptionLabel
@onready var sphincter_effect_value_label: Label = %SphincterEffectValueLabel
@onready var sphincter_effect_description_label: Label = %SphincterEffectDescriptionLabel
@onready var large_intestine_buy_button: Button = %LargeIntestineBuyButton
@onready var abdominal_buy_button: Button = %AbdominalBuyButton
@onready var sphincter_buy_button: Button = %SphincterBuyButton
@onready var temporary_leave_shop_button: Button = %TemporaryLeaveShopButton


# 进入商店时连接器官状态并同步新商店UI。
func _ready() -> void:
	OrganProgression.organ_upgraded.connect(_on_organ_upgraded)
	temporary_leave_shop_button.disabled = GameState.is_final_day()
	_update_shop_ui()


# 统一刷新新UI中的总金钱和器官信息。
func _update_shop_ui() -> void:
	total_money_label.text = "TOTAL MONEY: $%d" % Economy.total_money
	_update_organ_shop_ui()


# 刷新三个器官效果和购买按钮状态。
func _update_organ_shop_ui() -> void:
	var large_intestine: int = OrganProgression.Organ.LARGE_INTESTINE
	var sphincter: int = OrganProgression.Organ.SPHINCTER
	var abdominal_muscles: int = OrganProgression.Organ.ABDOMINAL_MUSCLES

	large_intestine_effect_value_label.text = _format_centimeters_as_feet(
		PlayerStats.get_effective_storage_capacity_cm()
	)
	large_intestine_effect_description_label.text = "OF POOP STORED"
	abdominal_effect_value_label.text = _format_centimeters_as_feet(
		ToiletScript.get_max_charged_push_distance_cm_without_food()
	)
	abdominal_effect_description_label.text = "PER FULL CHARGE"
	sphincter_effect_value_label.text = OrganProgression.get_sphincter_risk_state()
	sphincter_effect_description_label.text = "BREAK RISK"

	_update_organ_buy_button(large_intestine, large_intestine_buy_button)
	_update_organ_buy_button(abdominal_muscles, abdominal_buy_button)
	_update_organ_buy_button(sphincter, sphincter_buy_button)


# 同步指定器官的下一价格和余额状态。
func _update_organ_buy_button(organ: int, buy_button: Button) -> void:
	if OrganProgression.is_max_level(organ):
		buy_button.text = "MAX"
		buy_button.disabled = true
		return

	buy_button.text = "BUY %d" % OrganProgression.get_next_upgrade_price(organ)
	buy_button.disabled = not OrganProgression.can_upgrade(organ)


# 将厘米向下截断到一位小数后显示为英尺。
func _format_centimeters_as_feet(length_cm: float) -> String:
	var feet_tenths: int = floori(maxf(length_cm, 0.0) / CENTIMETERS_PER_FOOT * 10.0)
	if feet_tenths % 10 == 0:
		return "%d FT" % (feet_tenths / 10)
	return "%.1f FT" % (float(feet_tenths) / 10.0)


func _on_large_intestine_buy_button_pressed() -> void:
	_try_purchase_organ(OrganProgression.Organ.LARGE_INTESTINE)


func _on_abdominal_buy_button_pressed() -> void:
	_try_purchase_organ(OrganProgression.Organ.ABDOMINAL_MUSCLES)


func _on_sphincter_buy_button_pressed() -> void:
	_try_purchase_organ(OrganProgression.Organ.SPHINCTER)


# 防止按钮处理重入，并复用唯一的器官购买接口。
func _try_purchase_organ(organ: int) -> void:
	if is_processing_organ_purchase:
		return

	is_processing_organ_purchase = true
	large_intestine_buy_button.disabled = true
	abdominal_buy_button.disabled = true
	sphincter_buy_button.disabled = true
	var did_upgrade: bool = OrganProgression.try_upgrade_organ(organ)
	is_processing_organ_purchase = false
	if not did_upgrade:
		_update_shop_ui()


func _on_organ_upgraded(_organ: int, _new_level: int) -> void:
	_update_shop_ui()


# 临时离开按钮沿用既有的食物激活与跨天流程。
func _on_temporary_leave_shop_button_pressed() -> void:
	if has_advanced_day or GameState.is_final_day():
		return

	has_advanced_day = true
	temporary_leave_shop_button.disabled = true
	FoodSystem.activate_pending_foods()
	GameState.advance_day()
	var error: Error = get_tree().change_scene_to_file(GameState.DAY_START_SCENE_PATH)
	if error != OK:
		has_advanced_day = false
		temporary_leave_shop_button.disabled = false
		push_error("Failed to leave shop: %s" % error_string(error))

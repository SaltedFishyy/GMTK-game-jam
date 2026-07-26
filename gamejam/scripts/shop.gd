extends Control

const FoodDefinitionsScript = preload("res://scripts/food/food_definitions.gd")
const ToiletScript = preload("res://scripts/toilet.gd")
const CENTIMETERS_PER_FOOT: float = 30.48

var has_advanced_day: bool = false
var is_processing_organ_purchase: bool = false
var food_offer_ids: Array[int] = []

@onready var total_money_label: Label = %TotalMoneyLabel
@onready var large_intestine_effect_value_label: Label = %LargeIntestineEffectValueLabel
@onready var abdominal_effect_value_label: Label = %AbdominalEffectValueLabel
@onready var sphincter_effect_value_label: Label = %SphincterEffectValueLabel
@onready var large_intestine_buy_button: TextureButton = %LargeIntestineBuyButton
@onready var abdominal_buy_button: TextureButton = %AbdominalBuyButton
@onready var sphincter_buy_button: TextureButton = %SphincterBuyButton
@onready var large_intestine_price_label: Label = %LargeIntestinePriceLabel
@onready var abdominal_price_label: Label = %AbdominalPriceLabel
@onready var sphincter_price_label: Label = %SphincterPriceLabel
@onready var food_offer_controls: Array[Control] = [
	%FoodOffer1,
	%FoodOffer2,
	%FoodOffer3,
]
@onready var food_offer_buttons: Array[TextureButton] = [
	%FoodOffer1Button,
	%FoodOffer2Button,
	%FoodOffer3Button,
]
@onready var food_price_labels: Array[Label] = [
	%FoodOffer1PriceLabel,
	%FoodOffer2PriceLabel,
	%FoodOffer3PriceLabel,
]
@onready var food_status_labels: Array[Label] = [
	%FoodOffer1StatusLabel,
	%FoodOffer2StatusLabel,
	%FoodOffer3StatusLabel,
]
@onready var food_tooltip: PanelContainer = %FoodTooltip
@onready var food_name_label: Label = %FoodNameLabel
@onready var food_effects_label: Label = %FoodEffectsLabel
@onready var temporary_leave_shop_button: Button = %TemporaryLeaveShopButton


# 进入商店时连接器官状态并同步新商店UI。
func _ready() -> void:
	OrganProgression.organ_upgraded.connect(_on_organ_upgraded)
	FoodSystem.ensure_shop_offers(GameState.current_day)
	FoodSystem.food_state_changed.connect(_on_food_state_changed)
	_connect_food_offer_controls()
	temporary_leave_shop_button.disabled = GameState.is_final_day()
	_update_shop_ui()


# 统一刷新新UI中的总金钱和器官信息。
func _update_shop_ui() -> void:
	total_money_label.text = "TOTAL MONEY: $%d" % Economy.total_money
	_update_organ_shop_ui()
	_update_food_offers_ui()


# 三个商品格复用同一组购买与Hover处理函数。
func _connect_food_offer_controls() -> void:
	for index: int in range(food_offer_controls.size()):
		food_offer_buttons[index].pressed.connect(_on_food_offer_pressed.bind(index))
		food_offer_controls[index].mouse_entered.connect(_on_food_offer_mouse_entered.bind(index))
		food_offer_controls[index].mouse_exited.connect(_on_food_offer_mouse_exited)


# 只读取FoodSystem保存的固定商品，不在刷新时重新随机。
func _update_food_offers_ui() -> void:
	food_offer_ids = FoodSystem.get_current_shop_offers()
	for index: int in range(food_offer_controls.size()):
		if index >= food_offer_ids.size():
			food_offer_controls[index].hide()
			continue

		food_offer_controls[index].show()
		_update_food_offer(index, food_offer_ids[index])


# 将唯一食物定义同步到一个商品格。
func _update_food_offer(index: int, food_id: int) -> void:
	var definition: Dictionary = FoodDefinitionsScript.get_food(food_id)
	var normal_texture: Texture2D = definition["icon"] as Texture2D
	var purchased_texture: Texture2D = definition.get("purchased_texture") as Texture2D
	var is_purchased: bool = FoodSystem.has_pending_food(food_id)
	var includes_labels: bool = bool(definition.get("purchased_texture_includes_labels", false))
	var button: TextureButton = food_offer_buttons[index]

	button.texture_normal = normal_texture
	button.texture_hover = normal_texture
	button.texture_pressed = normal_texture
	button.texture_disabled = (
		purchased_texture if is_purchased and purchased_texture != null else normal_texture
	)
	button.disabled = is_purchased or not FoodSystem.can_purchase_food(food_id)
	food_price_labels[index].text = "$%d" % int(definition["price"])
	food_price_labels[index].visible = not (is_purchased and includes_labels)
	food_status_labels[index].text = "BOUGHT" if is_purchased else ""
	food_status_labels[index].visible = is_purchased and not includes_labels


func _on_food_offer_pressed(index: int) -> void:
	if index < 0 or index >= food_offer_ids.size():
		return
	FoodSystem.try_purchase_food(food_offer_ids[index])


# Tooltip由商品格处理，因此购买后按钮禁用仍可查看效果。
func _on_food_offer_mouse_entered(index: int) -> void:
	if index < 0 or index >= food_offer_ids.size():
		return

	var definition: Dictionary = FoodDefinitionsScript.get_food(food_offer_ids[index])
	food_name_label.text = String(definition["display_name"])
	food_effects_label.text = (
		"Charge %+d | Storage %+d\nSmoothness %+d | Integrity %+d | Value x%.2f"
		% [
			int(definition["charge_bonus"]),
			int(definition["storage_bonus"]),
			int(definition["smoothness_bonus"]),
			int(definition["integrity_bonus"]),
			float(definition["value_multiplier"]),
		]
	)
	food_tooltip.show()
	_position_food_tooltip(food_offer_controls[index])


func _on_food_offer_mouse_exited() -> void:
	food_tooltip.hide()


# 优先显示在商品右侧，并限制在当前视口范围内。
func _position_food_tooltip(food_offer: Control) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var desired_position: Vector2 = (
		food_offer.global_position + Vector2(food_offer.size.x + 8.0, 0.0)
	)
	var maximum_position: Vector2 = Vector2(
		maxf(viewport_size.x - food_tooltip.size.x - 8.0, 8.0),
		maxf(viewport_size.y - food_tooltip.size.y - 8.0, 8.0)
	)
	food_tooltip.global_position = Vector2(
		clampf(desired_position.x, 8.0, maximum_position.x),
		clampf(desired_position.y, 8.0, maximum_position.y)
	)


# 刷新三个器官效果和购买按钮状态。
func _update_organ_shop_ui() -> void:
	var large_intestine: int = OrganProgression.Organ.LARGE_INTESTINE
	var sphincter: int = OrganProgression.Organ.SPHINCTER
	var abdominal_muscles: int = OrganProgression.Organ.ABDOMINAL_MUSCLES

	large_intestine_effect_value_label.text = _format_centimeters_as_feet(
		PlayerStats.get_effective_storage_capacity_cm()
	)
	abdominal_effect_value_label.text = _format_centimeters_as_feet(
		ToiletScript.get_max_charged_push_distance_cm_without_food()
	)
	sphincter_effect_value_label.text = OrganProgression.get_sphincter_risk_state()

	_update_organ_buy_button(
		large_intestine, large_intestine_buy_button, large_intestine_price_label
	)
	_update_organ_buy_button(abdominal_muscles, abdominal_buy_button, abdominal_price_label)
	_update_organ_buy_button(sphincter, sphincter_buy_button, sphincter_price_label)


# 同步指定器官的下一价格和余额状态。
func _update_organ_buy_button(organ: int, buy_button: TextureButton, price_label: Label) -> void:
	if OrganProgression.is_max_level(organ):
		price_label.text = "MAX"
		buy_button.disabled = true
		return

	var upgrade_price: int = OrganProgression.get_next_upgrade_price(organ)
	price_label.text = _get_organ_purchase_text(organ, upgrade_price)
	buy_button.disabled = not OrganProgression.can_upgrade(organ)


# 组合当前价格与该器官每次购买产生的实际效果。
func _get_organ_purchase_text(organ: int, upgrade_price: int) -> String:
	match organ:
		OrganProgression.Organ.LARGE_INTESTINE:
			var storage_bonus: String = _format_centimeters_as_feet(
				OrganProgression.LARGE_INTESTINE_STORAGE_BONUS_CM_PER_LEVEL
			)
			storage_bonus = storage_bonus.replace(" ", "")
			return "<%d> +%s" % [upgrade_price, storage_bonus]
		OrganProgression.Organ.ABDOMINAL_MUSCLES:
			var charge_bonus: String = _format_centimeters_as_feet(
				OrganProgression.ABDOMINAL_FULL_CHARGE_BONUS_CM_PER_LEVEL
			)
			charge_bonus = charge_bonus.replace(" ", "")
			return "<%d> +%s" % [upgrade_price, charge_bonus]
		OrganProgression.Organ.SPHINCTER:
			var current_state: String = OrganProgression.get_sphincter_risk_state()
			var next_state: String = OrganProgression.get_next_sphincter_risk_state()
			return "<%d> %s → %s" % [upgrade_price, current_state, next_state]
		_:
			return "<%d>" % upgrade_price


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


func _on_food_state_changed() -> void:
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

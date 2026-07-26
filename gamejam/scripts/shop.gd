extends Control

const FoodDefinitionsScript = preload("res://scripts/food/food_definitions.gd")
const PoopReserveScript = preload("res://scripts/poop_reserve.gd")

const ORGAN_LIST_PATH: String = (
	"MainMargin/MainColumn/ContentColumns/OrganUpgradesPanel/"
	+ "PanelMargin/OrganColumn/OrganScroll/OrganList"
)
const FOOD_LIST_PATH: String = (
	"MainMargin/MainColumn/ContentColumns/RightColumn/FoodShopPanel/"
	+ "PanelMargin/FoodColumn/FoodScroll/FoodList"
)
const QUEUE_PATH: String = (
	"MainMargin/MainColumn/ContentColumns/RightColumn/QueuedFoodPanel/"
	+ "PanelMargin/QueueColumn"
)

@onready var total_money_label: Label = (
	$MainMargin/MainColumn/HeaderContainer/TotalMoneyLabel
)
@onready var food_slots_label: Label = (
	$MainMargin/MainColumn/ContentColumns/RightColumn/FoodShopPanel/
	PanelMargin/FoodColumn/FoodSlotsLabel
)
@onready var queued_title_label: Label = get_node(
	QUEUE_PATH + "/QueuedTitleLabel"
)
@onready var queued_food_names_label: Label = get_node(
	QUEUE_PATH + "/QueuedFoodNamesLabel"
)
@onready var queued_effects_label: Label = get_node(
	QUEUE_PATH + "/QueuedEffectsLabel"
)
@onready var next_day_button: Button = (
	$MainMargin/MainColumn/FooterContainer/NextDayButton
)

@onready var stomach_effect_label: Label = get_node(
	ORGAN_LIST_PATH + "/StomachRow/RowMargin/Row/Info/EffectLabel"
)
@onready var stomach_level_label: Label = get_node(
	ORGAN_LIST_PATH + "/StomachRow/RowMargin/Row/Status/LevelLabel"
)
@onready var stomach_price_label: Label = get_node(
	ORGAN_LIST_PATH + "/StomachRow/RowMargin/Row/Status/PriceLabel"
)
@onready var stomach_upgrade_button: Button = get_node(
	ORGAN_LIST_PATH + "/StomachRow/RowMargin/Row/UpgradeButton"
)

@onready var large_intestine_effect_label: Label = get_node(
	ORGAN_LIST_PATH + "/LargeIntestineRow/RowMargin/Row/Info/EffectLabel"
)
@onready var large_intestine_level_label: Label = get_node(
	ORGAN_LIST_PATH + "/LargeIntestineRow/RowMargin/Row/Status/LevelLabel"
)
@onready var large_intestine_price_label: Label = get_node(
	ORGAN_LIST_PATH + "/LargeIntestineRow/RowMargin/Row/Status/PriceLabel"
)
@onready var large_intestine_upgrade_button: Button = get_node(
	ORGAN_LIST_PATH + "/LargeIntestineRow/RowMargin/Row/UpgradeButton"
)

@onready var sphincter_effect_label: Label = get_node(
	ORGAN_LIST_PATH + "/SphincterRow/RowMargin/Row/Info/EffectLabel"
)
@onready var sphincter_level_label: Label = get_node(
	ORGAN_LIST_PATH + "/SphincterRow/RowMargin/Row/Status/LevelLabel"
)
@onready var sphincter_price_label: Label = get_node(
	ORGAN_LIST_PATH + "/SphincterRow/RowMargin/Row/Status/PriceLabel"
)
@onready var sphincter_upgrade_button: Button = get_node(
	ORGAN_LIST_PATH + "/SphincterRow/RowMargin/Row/UpgradeButton"
)

@onready var abdominal_muscles_effect_label: Label = get_node(
	ORGAN_LIST_PATH + "/AbsRow/RowMargin/Row/Info/EffectLabel"
)
@onready var abdominal_muscles_level_label: Label = get_node(
	ORGAN_LIST_PATH + "/AbsRow/RowMargin/Row/Status/LevelLabel"
)
@onready var abdominal_muscles_price_label: Label = get_node(
	ORGAN_LIST_PATH + "/AbsRow/RowMargin/Row/Status/PriceLabel"
)
@onready var abdominal_muscles_upgrade_button: Button = get_node(
	ORGAN_LIST_PATH + "/AbsRow/RowMargin/Row/UpgradeButton"
)

@onready var prune_name_label: Label = get_node(
	FOOD_LIST_PATH + "/PruneRow/Info/NameLabel"
)
@onready var prune_effect_label: Label = get_node(
	FOOD_LIST_PATH + "/PruneRow/Info/EffectLabel"
)
@onready var prune_food_button: Button = get_node(
	FOOD_LIST_PATH + "/PruneRow/BuyButton"
)
@onready var coffee_name_label: Label = get_node(
	FOOD_LIST_PATH + "/CoffeeRow/Info/NameLabel"
)
@onready var coffee_effect_label: Label = get_node(
	FOOD_LIST_PATH + "/CoffeeRow/Info/EffectLabel"
)
@onready var coffee_food_button: Button = get_node(
	FOOD_LIST_PATH + "/CoffeeRow/BuyButton"
)
@onready var sweet_potato_name_label: Label = get_node(
	FOOD_LIST_PATH + "/SweetPotatoRow/Info/NameLabel"
)
@onready var sweet_potato_effect_label: Label = get_node(
	FOOD_LIST_PATH + "/SweetPotatoRow/Info/EffectLabel"
)
@onready var sweet_potato_food_button: Button = get_node(
	FOOD_LIST_PATH + "/SweetPotatoRow/BuyButton"
)
@onready var avocado_name_label: Label = get_node(
	FOOD_LIST_PATH + "/AvocadoRow/Info/NameLabel"
)
@onready var avocado_effect_label: Label = get_node(
	FOOD_LIST_PATH + "/AvocadoRow/Info/EffectLabel"
)
@onready var avocado_food_button: Button = get_node(
	FOOD_LIST_PATH + "/AvocadoRow/BuyButton"
)
@onready var corn_name_label: Label = get_node(
	FOOD_LIST_PATH + "/CornRow/Info/NameLabel"
)
@onready var corn_effect_label: Label = get_node(
	FOOD_LIST_PATH + "/CornRow/Info/EffectLabel"
)
@onready var corn_food_button: Button = get_node(
	FOOD_LIST_PATH + "/CornRow/BuyButton"
)

var has_advanced_day: bool = false


# 进入商店时连接现有状态信号并同步全部占位UI。
func _ready() -> void:
	OrganProgression.organ_upgraded.connect(_on_organ_upgraded)
	FoodSystem.food_state_changed.connect(_on_food_state_changed)
	next_day_button.disabled = GameState.is_final_day()
	_update_shop_ui()


# 统一刷新总金钱、器官、食物和下一天排队预览。
func _update_shop_ui() -> void:
	total_money_label.text = "TOTAL MONEY: $%d" % Economy.total_money
	_update_organ_shop_ui()
	_update_food_shop_ui()
	_update_queued_food_ui()


# 刷新四种器官的等级、效果、价格和按钮状态。
func _update_organ_shop_ui() -> void:
	var stomach: int = OrganProgression.Organ.STOMACH
	var large_intestine: int = OrganProgression.Organ.LARGE_INTESTINE
	var sphincter: int = OrganProgression.Organ.SPHINCTER
	var abdominal_muscles: int = OrganProgression.Organ.ABDOMINAL_MUSCLES

	stomach_effect_label.text = "FOOD SLOTS: %d" % (
		OrganProgression.get_food_slot_count()
	)
	_update_organ_row(
		stomach,
		stomach_level_label,
		stomach_price_label,
		stomach_upgrade_button
	)

	var reserve_size_cm: float = (
		float(PlayerStats.storage_capacity)
		* PoopReserveScript.CM_PER_STORAGE_POINT
	)
	large_intestine_effect_label.text = "RESERVE SIZE: %.0f cm" % reserve_size_cm
	_update_organ_row(
		large_intestine,
		large_intestine_level_label,
		large_intestine_price_label,
		large_intestine_upgrade_button
	)

	var sphincter_bonus: int = roundi(
		(OrganProgression.get_sphincter_qte_width_multiplier() - 1.0) * 100.0
	)
	sphincter_effect_label.text = "QTE ZONE WIDTH: +%d%%" % sphincter_bonus
	_update_organ_row(
		sphincter,
		sphincter_level_label,
		sphincter_price_label,
		sphincter_upgrade_button
	)

	var abdominal_bonus: int = roundi(
		(OrganProgression.get_abdominal_push_multiplier() - 1.0) * 100.0
	)
	abdominal_muscles_effect_label.text = (
		"CHARGED PUSH DISTANCE: +%d%%" % abdominal_bonus
	)
	_update_organ_row(
		abdominal_muscles,
		abdominal_muscles_level_label,
		abdominal_muscles_price_label,
		abdominal_muscles_upgrade_button
	)


# 将一个器官的通用购买状态同步到对应行。
func _update_organ_row(
	organ: int,
	level_label: Label,
	price_label: Label,
	upgrade_button: Button
) -> void:
	var current_level: int = OrganProgression.get_level(organ)
	level_label.text = "Lv. %d / %d" % [
		current_level,
		OrganProgression.MAX_LEVEL
	]

	if current_level >= OrganProgression.MAX_LEVEL:
		price_label.text = "MAX LEVEL"
		upgrade_button.text = "MAX"
		upgrade_button.disabled = true
		return

	var upgrade_price: int = OrganProgression.get_next_upgrade_price(organ)
	price_label.text = "NEXT: $%d" % upgrade_price
	upgrade_button.text = "UPGRADE"
	upgrade_button.disabled = not OrganProgression.can_upgrade(organ)


# 刷新食物槽和五种食物的目录内容与购买状态。
func _update_food_shop_ui() -> void:
	var slot_limit: int = OrganProgression.get_food_slot_count()
	food_slots_label.text = "FOOD SLOTS: %d / %d" % [
		FoodSystem.get_pending_food_count(),
		slot_limit
	]
	_update_food_row(
		prune_name_label,
		prune_effect_label,
		prune_food_button,
		FoodDefinitionsScript.Food.PRUNE,
		slot_limit
	)
	_update_food_row(
		coffee_name_label,
		coffee_effect_label,
		coffee_food_button,
		FoodDefinitionsScript.Food.COFFEE,
		slot_limit
	)
	_update_food_row(
		sweet_potato_name_label,
		sweet_potato_effect_label,
		sweet_potato_food_button,
		FoodDefinitionsScript.Food.SWEET_POTATO,
		slot_limit
	)
	_update_food_row(
		avocado_name_label,
		avocado_effect_label,
		avocado_food_button,
		FoodDefinitionsScript.Food.AVOCADO,
		slot_limit
	)
	_update_food_row(
		corn_name_label,
		corn_effect_label,
		corn_food_button,
		FoodDefinitionsScript.Food.CORN,
		slot_limit
	)


# 从唯一食物目录读取一行显示，不在场景或商店脚本复制数值。
func _update_food_row(
	name_label: Label,
	effect_label: Label,
	buy_button: Button,
	food_id: int,
	slot_limit: int
) -> void:
	var definition: Dictionary = FoodDefinitionsScript.get_food(food_id)
	name_label.text = "%s — $%d" % [
		String(definition["display_name"]),
		int(definition["price"])
	]
	effect_label.text = (
		"Charge %+d | Storage %+d | Smoothness %+d | Integrity %+d | Value x%.2f"
		% [
			int(definition["charge_bonus"]),
			int(definition["storage_bonus"]),
			int(definition["smoothness_bonus"]),
			int(definition["integrity_bonus"]),
			float(definition["value_multiplier"])
		]
	)

	if FoodSystem.has_pending_food(food_id):
		buy_button.text = "PURCHASED"
		buy_button.disabled = true
		return

	buy_button.text = "BUY"
	buy_button.disabled = not FoodSystem.can_purchase_food(food_id, slot_limit)


# 汇总待下一天生效的食物名称和五项效果。
func _update_queued_food_ui() -> void:
	var queued_day: int = mini(GameState.current_day + 1, GameState.MAX_DAYS)
	queued_title_label.text = "QUEUED FOR DAY %d" % queued_day

	var pending_food_ids: Array[int] = FoodSystem.get_pending_food_ids()
	if pending_food_ids.is_empty():
		queued_food_names_label.text = "EMPTY STOMACH"
		queued_effects_label.text = (
			"Charge +0 | Storage +0 | Smoothness +0 | "
			+ "Integrity +0 | Value x1.00"
		)
		return

	var food_names: PackedStringArray = []
	var charge_bonus: int = 0
	var storage_bonus: int = 0
	var smoothness_bonus: int = 0
	var integrity_bonus: int = 0

	for food_id: int in pending_food_ids:
		var definition: Dictionary = FoodDefinitionsScript.get_food(food_id)
		food_names.append(String(definition["display_name"]))
		charge_bonus += int(definition["charge_bonus"])
		storage_bonus += int(definition["storage_bonus"])
		smoothness_bonus += int(definition["smoothness_bonus"])
		integrity_bonus += int(definition["integrity_bonus"])

	var value_multiplier: float = FoodSystem.get_pending_value_multiplier()
	queued_food_names_label.text = ", ".join(food_names)
	queued_effects_label.text = (
		"Charge %+d | Storage %+d | Smoothness %+d | "
		+ "Integrity %+d | Value x%.2f"
	) % [
		charge_bonus,
		storage_bonus,
		smoothness_bonus,
		integrity_bonus,
		value_multiplier
	]


# 点击胃升级按钮时调用唯一的器官购买入口。
func _on_stomach_upgrade_button_pressed() -> void:
	OrganProgression.try_upgrade_organ(OrganProgression.Organ.STOMACH)
	_update_shop_ui()


# 点击大肠升级按钮时调用唯一的器官购买入口。
func _on_large_intestine_upgrade_button_pressed() -> void:
	OrganProgression.try_upgrade_organ(
		OrganProgression.Organ.LARGE_INTESTINE
	)
	_update_shop_ui()


# 点击括约肌升级按钮时调用唯一的器官购买入口。
func _on_sphincter_upgrade_button_pressed() -> void:
	OrganProgression.try_upgrade_organ(OrganProgression.Organ.SPHINCTER)
	_update_shop_ui()


# 点击腹肌升级按钮时调用唯一的器官购买入口。
func _on_abdominal_muscles_upgrade_button_pressed() -> void:
	OrganProgression.try_upgrade_organ(
		OrganProgression.Organ.ABDOMINAL_MUSCLES
	)
	_update_shop_ui()


# 购买西梅并刷新商店预览。
func _on_prune_food_button_pressed() -> void:
	_try_purchase_food(FoodDefinitionsScript.Food.PRUNE)


# 购买咖啡并刷新商店预览。
func _on_coffee_food_button_pressed() -> void:
	_try_purchase_food(FoodDefinitionsScript.Food.COFFEE)


# 购买红薯并刷新商店预览。
func _on_sweet_potato_food_button_pressed() -> void:
	_try_purchase_food(FoodDefinitionsScript.Food.SWEET_POTATO)


# 购买牛油果并刷新商店预览。
func _on_avocado_food_button_pressed() -> void:
	_try_purchase_food(FoodDefinitionsScript.Food.AVOCADO)


# 购买玉米并刷新商店预览。
func _on_corn_food_button_pressed() -> void:
	_try_purchase_food(FoodDefinitionsScript.Food.CORN)


# 使用当前胃槽位尝试完成一次食物购买。
func _try_purchase_food(food_id: int) -> void:
	FoodSystem.try_purchase_food(
		food_id,
		OrganProgression.get_food_slot_count()
	)
	_update_shop_ui()


# 器官升级完成后刷新商店，不在商店保存器官数据。
func _on_organ_upgraded(_organ: int, _new_level: int) -> void:
	_update_shop_ui()


# 食物购买状态变化后刷新槽位、按钮、总金钱和排队预览。
func _on_food_state_changed() -> void:
	_update_shop_ui()


# 点击NEXT DAY后只推进一次天数，并进入每日状态页。
func _on_next_day_button_pressed() -> void:
	if has_advanced_day or GameState.is_final_day():
		return

	has_advanced_day = true
	next_day_button.disabled = true
	FoodSystem.activate_pending_foods()
	GameState.advance_day()
	get_tree().change_scene_to_file(GameState.DAY_START_SCENE_PATH)

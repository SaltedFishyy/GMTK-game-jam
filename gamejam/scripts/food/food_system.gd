extends Node

signal food_state_changed

const FoodDefinitionsScript = preload("res://scripts/food/food_definitions.gd")
const MAX_VALUE_MULTIPLIER: float = 2.0

var pending_food_ids: Array[int] = []
var active_food_ids: Array[int] = []


# 清空待生效和当前生效食物，并通知现有UI监听者。
func reset_to_defaults() -> void:
	pending_food_ids.clear()
	active_food_ids.clear()
	food_state_changed.emit()


# 返回当前商店阶段是否可以购买指定食物。
func can_purchase_food(food_id: int, slot_limit: int) -> bool:
	if not FoodDefinitionsScript.is_valid_food(food_id):
		return false
	if pending_food_ids.has(food_id):
		return false
	if pending_food_ids.size() >= maxi(slot_limit, 0):
		return false

	var definition: Dictionary = FoodDefinitionsScript.get_food(food_id)
	return Economy.can_afford(int(definition["price"]))


# 安全扣钱并把食物加入下一轮待生效列表。
func try_purchase_food(food_id: int, slot_limit: int) -> bool:
	if not can_purchase_food(food_id, slot_limit):
		return false

	var definition: Dictionary = FoodDefinitionsScript.get_food(food_id)
	if not Economy.try_spend_money(int(definition["price"])):
		return false

	pending_food_ids.append(food_id)
	food_state_changed.emit()
	return true


# 点击NEXT DAY时让已购买食物只对下一轮厕所生效。
func activate_pending_foods() -> void:
	active_food_ids.clear()
	active_food_ids.assign(pending_food_ids)
	pending_food_ids.clear()
	food_state_changed.emit()


# 当前厕所回合结算后清除全部临时食物效果。
func clear_active_foods() -> void:
	if active_food_ids.is_empty():
		return

	active_food_ids.clear()
	food_state_changed.emit()


# 返回指定食物是否已在当前商店阶段购买。
func has_pending_food(food_id: int) -> bool:
	return pending_food_ids.has(food_id)


# 返回当前已占用的下一轮食物槽数量。
func get_pending_food_count() -> int:
	return pending_food_ids.size()


# 返回待下一天生效的食物编号副本，避免商店直接修改内部列表。
func get_pending_food_ids() -> Array[int]:
	return pending_food_ids.duplicate()


# 返回当前厕所回合生效食物编号的副本，避免UI修改内部列表。
func get_active_food_ids() -> Array[int]:
	return active_food_ids.duplicate()


# 返回待下一天生效食物的加法价值倍率，并限制在1.0到2.0。
func get_pending_value_multiplier() -> float:
	return _get_food_value_multiplier(pending_food_ids)


# 返回当前厕所回合的蓄力等级加成。
func get_active_charge_bonus() -> int:
	return _get_active_integer_bonus("charge_bonus")


# 返回当前厕所回合的储存量加成。
func get_active_storage_bonus() -> int:
	return _get_active_integer_bonus("storage_bonus")


# 返回当前厕所回合的顺滑度加成。
func get_active_smoothness_bonus() -> int:
	return _get_active_integer_bonus("smoothness_bonus")


# 返回当前厕所回合的完整度加成。
func get_active_integrity_bonus() -> int:
	return _get_active_integer_bonus("integrity_bonus")


# 以加法合并当前食物价值，并限制在1.0到2.0。
func get_active_value_multiplier() -> float:
	return _get_food_value_multiplier(active_food_ids)


# 使用同一份规则合计指定食物列表的价值倍率。
func _get_food_value_multiplier(food_ids: Array[int]) -> float:
	var multiplier: float = 1.0
	for food_id: int in food_ids:
		var definition: Dictionary = FoodDefinitionsScript.get_food(food_id)
		multiplier += float(definition["value_multiplier"]) - 1.0
	return clampf(multiplier, 1.0, MAX_VALUE_MULTIPLIER)


# 累加当前生效食物的指定整数属性。
func _get_active_integer_bonus(property_name: String) -> int:
	var total_bonus: int = 0
	for food_id: int in active_food_ids:
		var definition: Dictionary = FoodDefinitionsScript.get_food(food_id)
		total_bonus += int(definition[property_name])
	return total_bonus

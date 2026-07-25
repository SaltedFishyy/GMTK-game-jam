class_name FoodDefinitions
extends RefCounted

enum Food {
	PRUNE,
	COFFEE,
	SWEET_POTATO,
	AVOCADO,
	CORN,
}

const FOODS: Dictionary = {
	Food.PRUNE: {
		"display_name": "PRUNE",
		"price": 5,
		"charge_bonus": 1,
		"storage_bonus": 2,
		"smoothness_bonus": 3,
		"integrity_bonus": -1,
		"value_multiplier": 1.0,
	},
	Food.COFFEE: {
		"display_name": "COFFEE",
		"price": 5,
		"charge_bonus": 2,
		"storage_bonus": 0,
		"smoothness_bonus": 2,
		"integrity_bonus": -2,
		"value_multiplier": 1.0,
	},
	Food.SWEET_POTATO: {
		"display_name": "SWEET POTATO",
		"price": 10,
		"charge_bonus": 0,
		"storage_bonus": 3,
		"smoothness_bonus": -2,
		"integrity_bonus": 2,
		"value_multiplier": 1.2,
	},
	Food.AVOCADO: {
		"display_name": "AVOCADO",
		"price": 15,
		"charge_bonus": 1,
		"storage_bonus": 2,
		"smoothness_bonus": 2,
		"integrity_bonus": 1,
		"value_multiplier": 1.3,
	},
	Food.CORN: {
		"display_name": "CORN",
		"price": 15,
		"charge_bonus": 0,
		"storage_bonus": 0,
		"smoothness_bonus": 0,
		"integrity_bonus": 0,
		"value_multiplier": 1.35,
	},
}


# 返回第一版全部食物编号。
static func get_all_food_ids() -> Array[int]:
	return [
		Food.PRUNE,
		Food.COFFEE,
		Food.SWEET_POTATO,
		Food.AVOCADO,
		Food.CORN,
	]


# 返回食物编号是否存在于第一版定义中。
static func is_valid_food(food_id: int) -> bool:
	return FOODS.has(food_id)


# 返回指定食物的只读定义；无效编号返回空字典。
static func get_food(food_id: int) -> Dictionary:
	return FOODS.get(food_id, {})

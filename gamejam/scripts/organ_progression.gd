extends Node

signal organ_upgraded(organ: int, new_level: int)

enum Organ {
	LARGE_INTESTINE,
	SPHINCTER,
	ABDOMINAL_MUSCLES,
}

const UPGRADE_COST_STEP: int = 30
const SPHINCTER_MAX_LEVEL: int = 2
const LARGE_INTESTINE_STORAGE_BONUS_FEET_PER_LEVEL: float = 3.0
const ABDOMINAL_FULL_CHARGE_BONUS_FEET_PER_LEVEL: float = 1.5

var large_intestine_level: int = 0
var sphincter_level: int = 0
var abdominal_muscles_level: int = 0


# 将三种器官恢复为0级。
func reset_to_defaults() -> void:
	large_intestine_level = 0
	sphincter_level = 0
	abdominal_muscles_level = 0


# 返回指定器官当前等级，无效器官返回0。
func get_level(organ: int) -> int:
	match organ:
		Organ.LARGE_INTESTINE:
			return large_intestine_level
		Organ.SPHINCTER:
			return sphincter_level
		Organ.ABDOMINAL_MUSCLES:
			return abdominal_muscles_level
		_:
			return 0


# 根据当前等级返回下一级价格，满级或无效器官返回0。
func get_next_upgrade_price(organ: int) -> int:
	if not _can_increase_level(organ):
		return 0
	return (get_level(organ) + 1) * UPGRADE_COST_STEP

# 返回大肠等级提供的额外每轮储备厘米数。
func get_large_intestine_storage_bonus_cm() -> float:
	return LengthUnits.feet_to_cm(
		float(large_intestine_level)
		* LARGE_INTESTINE_STORAGE_BONUS_FEET_PER_LEVEL
	)


# 返回腹肌等级在满蓄力时提供的额外推出厘米数。
func get_abdominal_full_charge_bonus_cm() -> float:
	return LengthUnits.feet_to_cm(
		float(abdominal_muscles_level)
		* ABDOMINAL_FULL_CHARGE_BONUS_FEET_PER_LEVEL
	)


# 返回括约肌当前只用于界面显示的夹断风险状态。
func get_sphincter_risk_state() -> String:
	match sphincter_level:
		0:
			return "HIGH"
		1:
			return "MID"
		_:
			return "LOW"


# 返回购买下一次括约肌升级后用于界面显示的风险状态。
func get_next_sphincter_risk_state() -> String:
	if sphincter_level <= 0:
		return "MID"
	return "LOW"


# 返回指定器官是否已经达到自身上限。
func is_max_level(organ: int) -> bool:
	return organ == Organ.SPHINCTER and sphincter_level >= SPHINCTER_MAX_LEVEL


# 返回当前等级与余额是否允许完成一次付费升级。
func can_upgrade(organ: int) -> bool:
	if not _can_increase_level(organ):
		return false
	return Economy.can_afford(get_next_upgrade_price(organ))


# 尝试扣钱并提升指定器官，成功后应用效果并发出信号。
func try_upgrade_organ(organ: int) -> bool:
	if not _can_increase_level(organ):
		return false

	var upgrade_price: int = get_next_upgrade_price(organ)
	if not Economy.try_spend_money(upgrade_price):
		return false

	_increase_level(organ)

	var new_level: int = get_level(organ)
	organ_upgraded.emit(organ, new_level)
	return true


# 返回器官编号有效且尚未达到最高等级。
func _can_increase_level(organ: int) -> bool:
	return _is_valid_organ(organ) and not is_max_level(organ)


# 将已经验证过的器官提升一级。
func _increase_level(organ: int) -> void:
	match organ:
		Organ.LARGE_INTESTINE:
			large_intestine_level += 1
		Organ.SPHINCTER:
			sphincter_level += 1
		Organ.ABDOMINAL_MUSCLES:
			abdominal_muscles_level += 1


# 返回器官编号是否属于当前三种器官。
func _is_valid_organ(organ: int) -> bool:
	return organ >= Organ.LARGE_INTESTINE and organ <= Organ.ABDOMINAL_MUSCLES

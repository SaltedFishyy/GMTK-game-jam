extends Node

signal organ_upgraded(organ: int, new_level: int)

enum Organ {
	STOMACH,
	LARGE_INTESTINE,
	SPHINCTER,
	ABDOMINAL_MUSCLES,
}

const MAX_LEVEL: int = 5
const UPGRADE_COST_STEP: int = 30
const ABDOMINAL_PUSH_BONUS_PER_LEVEL: float = 0.1
const SPHINCTER_QTE_WIDTH_BONUS_PER_LEVEL: float = 0.1

var stomach_level: int = 0
var large_intestine_level: int = 0
var sphincter_level: int = 0
var abdominal_muscles_level: int = 0


# 将四种器官恢复为0级，派生食物槽会自动恢复为1。
func reset_to_defaults() -> void:
	stomach_level = 0
	large_intestine_level = 0
	sphincter_level = 0
	abdominal_muscles_level = 0


# 返回指定器官当前等级，无效器官返回0。
func get_level(organ: int) -> int:
	match organ:
		Organ.STOMACH:
			return stomach_level
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


# 根据胃等级返回当前食物槽数量，不保存重复的槽位状态。
func get_food_slot_count() -> int:
	return 1 + get_level(Organ.STOMACH)


# 返回腹肌等级提供的长按推出距离倍率。
func get_abdominal_push_multiplier() -> float:
	return 1.0 + float(abdominal_muscles_level) * ABDOMINAL_PUSH_BONUS_PER_LEVEL


# 返回括约肌等级提供的QTE目标区域宽度倍率。
func get_sphincter_qte_width_multiplier() -> float:
	return 1.0 + float(sphincter_level) * SPHINCTER_QTE_WIDTH_BONUS_PER_LEVEL


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
	if organ == Organ.LARGE_INTESTINE:
		PlayerStats.upgrade_storage_capacity(1)

	var new_level: int = get_level(organ)
	organ_upgraded.emit(organ, new_level)
	return true


# 返回器官编号有效且尚未达到最高等级。
func _can_increase_level(organ: int) -> bool:
	return _is_valid_organ(organ) and get_level(organ) < MAX_LEVEL


# 将已经验证过的器官提升一级。
func _increase_level(organ: int) -> void:
	match organ:
		Organ.STOMACH:
			stomach_level += 1
		Organ.LARGE_INTESTINE:
			large_intestine_level += 1
		Organ.SPHINCTER:
			sphincter_level += 1
		Organ.ABDOMINAL_MUSCLES:
			abdominal_muscles_level += 1


# 返回器官编号是否属于当前四种器官。
func _is_valid_organ(organ: int) -> bool:
	return organ >= Organ.STOMACH and organ <= Organ.ABDOMINAL_MUSCLES

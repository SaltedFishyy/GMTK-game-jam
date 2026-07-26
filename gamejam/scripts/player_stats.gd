extends Node

signal stats_changed(storage_capacity: int, smoothness: int, integrity: int)

const MIN_STAT_VALUE: int = 0
const MAX_STAT_VALUE: int = 10
const DEFAULT_STAT_VALUE: int = 5

@export_range(0, 10, 1) var storage_capacity: int = DEFAULT_STAT_VALUE:
	set(value):
		var safe_value: int = clampi(value, MIN_STAT_VALUE, MAX_STAT_VALUE)
		if storage_capacity == safe_value:
			return
		storage_capacity = safe_value
		if is_inside_tree():
			_emit_stats_changed()

@export_range(0, 10, 1) var smoothness: int = DEFAULT_STAT_VALUE:
	set(value):
		var safe_value: int = clampi(value, MIN_STAT_VALUE, MAX_STAT_VALUE)
		if smoothness == safe_value:
			return
		smoothness = safe_value
		if is_inside_tree():
			_emit_stats_changed()

@export_range(0, 10, 1) var integrity: int = DEFAULT_STAT_VALUE:
	set(value):
		var safe_value: int = clampi(value, MIN_STAT_VALUE, MAX_STAT_VALUE)
		if integrity == safe_value:
			return
		integrity = safe_value
		if is_inside_tree():
			_emit_stats_changed()


# 将三项永久基础属性恢复为本局初始值。
func reset_to_defaults() -> void:
	storage_capacity = DEFAULT_STAT_VALUE
	smoothness = DEFAULT_STAT_VALUE
	integrity = DEFAULT_STAT_VALUE


# 返回当前储存量。
func get_storage_capacity() -> int:
	return storage_capacity


# 返回叠加当前回合食物效果后的有效储存量。
func get_effective_storage_capacity() -> int:
	return clampi(
		storage_capacity + FoodSystem.get_active_storage_bonus(),
		MIN_STAT_VALUE,
		MAX_STAT_VALUE
	)


# 返回基础/食物储存点与大肠升级共同提供的本轮实际储备厘米数。
func get_effective_storage_capacity_cm() -> float:
	return (
		PoopReserve.get_max_reserve_cm_for_capacity(
			get_effective_storage_capacity()
		)
		+ OrganProgression.get_large_intestine_storage_bonus_cm()
	)


# 设置储存量，并限制在0到10。
func set_storage_capacity(value: int) -> void:
	storage_capacity = value


# 按指定整数增加储存量。
func upgrade_storage_capacity(amount: int = 1) -> void:
	set_storage_capacity(storage_capacity + amount)


# 返回当前顺滑度。
func get_smoothness() -> int:
	return smoothness


# 返回叠加当前回合食物效果后的有效顺滑度。
func get_effective_smoothness() -> int:
	return clampi(
		smoothness + FoodSystem.get_active_smoothness_bonus(),
		MIN_STAT_VALUE,
		MAX_STAT_VALUE
	)


# 设置顺滑度，并限制在0到10。
func set_smoothness(value: int) -> void:
	smoothness = value


# 按指定整数增加顺滑度。
func upgrade_smoothness(amount: int = 1) -> void:
	set_smoothness(smoothness + amount)


# 返回当前完整度。
func get_integrity() -> int:
	return integrity


# 返回叠加当前回合食物效果后的有效完整度。
func get_effective_integrity() -> int:
	return clampi(
		integrity + FoodSystem.get_active_integrity_bonus(),
		MIN_STAT_VALUE,
		MAX_STAT_VALUE
	)


# 设置完整度，并限制在0到10。
func set_integrity(value: int) -> void:
	integrity = value


# 按指定整数增加完整度。
func upgrade_integrity(amount: int = 1) -> void:
	set_integrity(integrity + amount)


# 通知监听者三个属性的最新值。
func _emit_stats_changed() -> void:
	stats_changed.emit(storage_capacity, smoothness, integrity)

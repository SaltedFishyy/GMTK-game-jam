class_name QTERules
extends RefCounted


# 根据顺滑度返回下一次QTE的随机等待范围。
static func get_wait_interval(
	smoothness: int,
	hard_minimum: float,
	hard_maximum: float,
	normal_minimum: float,
	normal_maximum: float
) -> Vector2:
	if smoothness <= 4:
		return Vector2(hard_minimum, hard_maximum)

	return Vector2(normal_minimum, normal_maximum)


# 根据顺滑度返回QTE指针速度。
static func get_pointer_speed(
	smoothness: int,
	normal_speed: float,
	loose_speed_multiplier: float
) -> float:
	if smoothness >= 8:
		return normal_speed * loose_speed_multiplier

	return normal_speed


# 根据完整度返回目标区域宽度倍率。
static func get_target_width_multiplier(
	integrity: int,
	high_integrity_multiplier: float
) -> float:
	if integrity >= 8:
		return high_integrity_multiplier

	return 1.0


# 根据完整度返回本次QTE所需的连续成功次数。
static func get_required_successes(integrity: int) -> int:
	if integrity >= 8:
		return 2

	return 1


# 返回完整度是否需要使用若隐若现的显示模式。
static func uses_faded_display(integrity: int) -> bool:
	return integrity <= 4

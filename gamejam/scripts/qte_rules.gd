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


# 根据顺滑度返回QTE轨道的基础移动速度。
static func get_track_speed(
	smoothness: int,
	normal_speed: float,
	loose_speed_multiplier: float
) -> float:
	if smoothness >= 8:
		return normal_speed * loose_speed_multiplier

	return normal_speed


# 根据括约肌等级返回QTE轨道速度倍率。
static func get_sphincter_track_speed_multiplier(sphincter_level: int) -> float:
	match sphincter_level:
		0:
			return 1.0
		1:
			return 0.85
		_:
			return 0.7


# 根据括约肌等级返回下一次QTE等待间隔倍率。
static func get_sphincter_interval_multiplier(sphincter_level: int) -> float:
	match sphincter_level:
		0:
			return 1.0
		1:
			return 1.25
		_:
			return 1.5


# 根据括约肌等级返回拼接目标区域需要显示的Center格数。
static func get_target_center_count(sphincter_level: int) -> int:
	match sphincter_level:
		0:
			return 3
		1:
			return 5
		_:
			return 7


# 根据完整度返回本次QTE所需的连续成功次数。
static func get_required_successes(integrity: int) -> int:
	if integrity >= 8:
		return 2

	return 1


# 返回完整度是否需要使用若隐若现的显示模式。
static func uses_faded_display(integrity: int) -> bool:
	return integrity <= 4

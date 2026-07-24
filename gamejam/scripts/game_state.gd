extends Node

const MAX_DAYS: int = 5
const MAX_CLOG_PROGRESS: float = 100.0
const TARGET_CLOG_PROGRESS: float = 80.0
const CLOG_PROGRESS_PER_CM: float = 2.0

var current_day: int = 1
var clog_progress: float = 0.0


# 增加跨天堵塞进度，并将结果限制在有效范围内。
func add_clog_progress(amount: float) -> void:
	clog_progress = clampf(
		clog_progress + maxf(amount, 0.0),
		0.0,
		MAX_CLOG_PROGRESS
	)


# 进入下一天，但不允许天数超过总天数。
func advance_day() -> void:
	current_day = mini(current_day + 1, MAX_DAYS)


# 返回当前是否已经是第5天。
func is_final_day() -> bool:
	return current_day >= MAX_DAYS


# 返回累计堵塞进度是否已经达到目标。
func is_clog_target_reached() -> bool:
	return clog_progress >= TARGET_CLOG_PROGRESS

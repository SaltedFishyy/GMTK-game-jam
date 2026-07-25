extends Node

const MAX_DAYS: int = 5
const MAX_CLOG_PROGRESS: float = 100.0
const TARGET_CLOG_PROGRESS: float = 80.0
const CLOG_PROGRESS_PER_CM: float = 2.0
const TOILET_SCENE_PATH: String = "res://scenes/toilet.tscn"

var current_day: int = 1
var clog_progress: float = 0.0


# 将天数和跨天堵塞进度恢复为本局初始值。
func reset_to_defaults() -> void:
	current_day = 1
	clog_progress = 0.0


# 协调全部跨场景系统重置，并从第1天厕所重新开始。
func restart_run() -> void:
	reset_to_defaults()
	Economy.reset_to_defaults()
	PlayerStats.reset_to_defaults()
	OrganProgression.reset_to_defaults()
	FoodSystem.reset_to_defaults()
	get_tree().paused = false

	var scene_change_error: Error = get_tree().change_scene_to_file(
		TOILET_SCENE_PATH
	)
	if scene_change_error != OK:
		push_error(
			"Failed to restart run: could not load %s (error %d)."
			% [TOILET_SCENE_PATH, scene_change_error]
		)


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

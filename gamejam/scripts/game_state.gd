extends Node

const MAX_DAYS: int = 5
const MAX_CLOG_PROGRESS: float = 120.0
const TARGET_CLOG_PROGRESS: float = 200.0
const CLOG_PROGRESS_PER_CM: float = 2.0
const TOILET_SCENE_PATH: String = "res://scenes/toilet.tscn"
const DAY_START_SCENE_PATH: String = "res://day_start.tscn"
const END_DAY_SCENE_PATH: String = "res://scenes/end_day.tscn"

var current_day: int = 1
var clog_progress: float = 0.0
var has_last_round_result: bool = false
var last_round_day: int = 0
var last_round_longest_streak_cm: float = 0.0
var last_round_clog_progress: float = 0.0
var last_round_distance_remaining_cm: float = 0.0
var last_round_payout: int = 0


# 将天数和当天堵塞进度恢复为本局初始值。
func reset_to_defaults() -> void:
	current_day = 1
	reset_daily_clog_progress()
	clear_last_round_result()


# 协调全部跨场景系统重置，并从第1天每日状态页重新开始。
func restart_run() -> void:
	reset_to_defaults()
	Economy.reset_to_defaults()
	PlayerStats.reset_to_defaults()
	OrganProgression.reset_to_defaults()
	FoodSystem.reset_to_defaults()
	get_tree().paused = false

	var scene_change_error: Error = get_tree().change_scene_to_file(DAY_START_SCENE_PATH)
	if scene_change_error != OK:
		push_error(
			(
				"Failed to restart run: could not load %s (error %d)."
				% [DAY_START_SCENE_PATH, scene_change_error]
			)
		)


# 将本轮实时变化量应用到当天堵塞进度，并限制在有效范围内。
func apply_daily_clog_progress_delta(amount: float) -> void:
	clog_progress = clampf(
		clog_progress + amount,
		0.0,
		MAX_CLOG_PROGRESS
	)


# 清空当天堵塞进度，不修改天数或其他跨场景状态。
func reset_daily_clog_progress() -> void:
	clog_progress = 0.0


# 保存刚完成厕所回合的只读展示快照；金钱与堵塞已由各自系统完成结算。
func save_last_round_result(
	day: int,
	longest_streak_cm: float,
	final_clog_progress: float,
	distance_remaining_cm: float,
	payout: int
) -> void:
	has_last_round_result = true
	last_round_day = clampi(day, 1, MAX_DAYS)
	last_round_longest_streak_cm = maxf(longest_streak_cm, 0.0)
	last_round_clog_progress = clampf(
		final_clog_progress,
		0.0,
		MAX_CLOG_PROGRESS
	)
	last_round_distance_remaining_cm = maxf(distance_remaining_cm, 0.0)
	last_round_payout = maxi(payout, 0)


# 清空上一轮展示快照，不修改当前天数、堵塞或金钱。
func clear_last_round_result() -> void:
	has_last_round_result = false
	last_round_day = 0
	last_round_longest_streak_cm = 0.0
	last_round_clog_progress = 0.0
	last_round_distance_remaining_cm = 0.0
	last_round_payout = 0


# 进入下一天，但不允许天数超过总天数。
func advance_day() -> void:
	if current_day >= MAX_DAYS:
		return

	current_day += 1
	reset_daily_clog_progress()


# 返回当前是否已经是第5天。
func is_final_day() -> bool:
	return current_day >= MAX_DAYS


# 返回当天堵塞进度是否已经达到目标。
func is_clog_target_reached() -> bool:
	return clog_progress >= TARGET_CLOG_PROGRESS

extends Node

const MAX_DAYS: int = 5
const CLOG_TARGET_FEET: float = 28
const TOILET_SCENE_PATH: String = "res://scenes/toilet.tscn"
const DAY_START_SCENE_PATH: String = "res://day_start.tscn"
const END_DAY_SCENE_PATH: String = "res://scenes/end_day.tscn"
const WIN_SCENE_PATH: String = "res://scenes/win.tscn"
const LOSE_SCENE_PATH: String = "res://Losescreen.tscn"
const STARTING_PAGE_SCENE_PATH: String = "res://scenes/StartingPage.tscn"

var current_day: int = 1
var has_last_round_result: bool = false
var last_round_day: int = 0
var last_round_longest_streak_cm: float = 0.0
var last_round_total_length_cm: float = 0.0
var last_round_distance_remaining_cm: float = 0.0
var last_round_payout: int = 0


# 将天数和上一轮展示快照恢复为本局初始值。
func reset_to_defaults() -> void:
	current_day = 1
	clear_last_round_result()


# 协调全部跨场景系统重置，并从第1天每日状态页重新开始。
func restart_run() -> void:
	reset_run_progress()
	_change_scene_after_reset(DAY_START_SCENE_PATH, "restart run")


# 清空当前本局并返回正式StartingPage，不在PauseMenu中复制跨场景重置逻辑。
func return_to_starting_page() -> void:
	reset_run_progress()
	_change_scene_after_reset(STARTING_PAGE_SCENE_PATH, "return home")


# 统一协调所有现有Autoload恢复各自负责的默认数据。
func reset_run_progress() -> void:
	reset_to_defaults()
	Economy.reset_to_defaults()
	PlayerStats.reset_to_defaults()
	OrganProgression.reset_to_defaults()
	FoodSystem.reset_to_defaults()


# 重置入口统一解除暂停并检查场景切换错误。
func _change_scene_after_reset(scene_path: String, action_name: String) -> void:
	get_tree().paused = false
	var scene_change_error: Error = get_tree().change_scene_to_file(scene_path)
	if scene_change_error != OK:
		push_error(
			"Failed to %s: could not load %s (error %d)."
			% [action_name, scene_path, scene_change_error]
		)


# 保存刚完成厕所回合的只读展示快照；金钱已由Economy完成结算。
func save_last_round_result(
	day: int,
	longest_streak_cm: float,
	final_total_length_cm: float,
	distance_remaining_cm: float,
	payout: int
) -> void:
	has_last_round_result = true
	last_round_day = clampi(day, 1, MAX_DAYS)
	last_round_longest_streak_cm = maxf(longest_streak_cm, 0.0)
	last_round_total_length_cm = maxf(final_total_length_cm, 0.0)
	last_round_distance_remaining_cm = maxf(distance_remaining_cm, 0.0)
	last_round_payout = maxi(payout, 0)


# 清空上一轮展示快照，不修改当前天数或金钱。
func clear_last_round_result() -> void:
	has_last_round_result = false
	last_round_day = 0
	last_round_longest_streak_cm = 0.0
	last_round_total_length_cm = 0.0
	last_round_distance_remaining_cm = 0.0
	last_round_payout = 0


# 进入下一天，但不允许天数超过总天数。
func advance_day() -> void:
	if current_day >= MAX_DAYS:
		return

	current_day += 1


# 返回当前是否已经是第5天。
func is_final_day() -> bool:
	return current_day >= MAX_DAYS


# 将唯一堵塞目标配置安全换算为厘米，不保存第二份目标长度。
func get_clog_target_length_cm() -> float:
	return maxf(LengthUnits.feet_to_cm(CLOG_TARGET_FEET), 0.0)


# 返回本轮全部Poop段的实际总长度是否已经达到唯一堵塞长度目标。
func is_clog_target_length_reached(total_length_cm: float) -> bool:
	var target_length_cm: float = get_clog_target_length_cm()
	return target_length_cm > 0.0 and total_length_cm >= target_length_cm

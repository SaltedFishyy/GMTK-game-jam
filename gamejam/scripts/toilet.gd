extends Node2D

const POOP_SCENE: PackedScene = preload("res://scenes/poop.tscn")
const QTEBarScript = preload("res://scripts/components/qte_bar.gd")
const QTERulesScript = preload("res://scripts/qte_rules.gd")
const PoopReserveScript = preload("res://scripts/poop_reserve.gd")
const SHOP_SCENE_PATH: String = "res://scenes/shop.tscn"
const STARTING_SECONDS: int = 10
const DEFAULT_MAX_CHARGE_PUSH_DISTANCE_PIXELS: float = 150.0

@export_range(1.0, 1000.0, 1.0, "suffix:px/s") var poop_move_speed: float = 400.0
@export_range(0.05, 1.0, 0.05, "suffix:s") var click_max_duration: float = 0.3
@export_range(1.0, 200.0, 1.0, "suffix:px") var click_push_distance: float = 20.0
@export_range(0.1, 5.0, 0.1, "suffix:s") var max_charge_duration: float = 3.0
@export_range(1.0, 300.0, 1.0, "suffix:px") var min_charge_push_distance: float = 40.0
@export_range(1.0, 300.0, 1.0, "suffix:px") var max_charge_push_distance: float = (
	DEFAULT_MAX_CHARGE_PUSH_DISTANCE_PIXELS
)
@export_range(0.0, 2.0, 0.05, "suffix:s") var idle_retract_delay: float = 0.3
@export_range(0.0, 200.0, 1.0, "suffix:px/s") var poop_retract_speed: float = 20.0
@export_range(0.1, 10.0, 0.1, "suffix:s") var hard_qte_min_interval: float = 1.0
@export_range(0.1, 10.0, 0.1, "suffix:s") var hard_qte_max_interval: float = 3.0
@export_range(0.1, 10.0, 0.1, "suffix:s") var normal_qte_min_interval: float = 2.0
@export_range(0.1, 10.0, 0.1, "suffix:s") var normal_qte_max_interval: float = 5.0
@export_range(10.0, 1200.0, 10.0, "suffix:px/s") var normal_qte_pointer_speed: float = 400.0
@export_range(1.0, 3.0, 0.1) var loose_qte_speed_multiplier: float = 1.5

@onready var countdown_label: Label = $CountdownLabel
@onready var length_label: Label = $LengthLabel
@onready var reserve_label: Label = $ReserveLabel
@onready var money_earned_label: Label = $MoneyEarnedLabel
@onready var day_label: Label = $DayLabel
@onready var clog_target_label: Label = $ClogTargetLabel
@onready var clog_progress_bar: ProgressBar = $ClogProgressBar
@onready var break_count_label: Label = $BreakCountLabel
@onready var charge_bar: ProgressBar = $ChargeBar
@onready var qte_bar: QTEBarScript = $QTEBar
@onready var qte_wait_timer: Timer = $QTEWaitTimer
@onready var result_label: Label = $ResultLabel
@onready var enter_shop_button: Button = $EnterShopButton
@onready var countdown_timer: Timer = $CountdownTimer
@onready var poop_spawn_marker: Marker2D = $PoopSpawnMarker
@onready var poop_end_marker: Marker2D = $PoopEndMarker

var seconds_remaining: int = STARTING_SECONDS
var has_round_started: bool = false
var is_round_active: bool = true
var final_length_cm: float = 0.0
var money_earned: int = 0
var has_settled_round: bool = false
var is_round_ending: bool = false
var is_mouse_button_down: bool = false
var has_active_mouse_action: bool = false
var hold_duration: float = 0.0
var poop_idle_duration: float = 0.0
var session_start_clog: float = 0.0
var session_clog_gain: float = 0.0
var break_count: int = 0
var current_qte_is_double: bool = false
var has_completed_double_qte: bool = false
var qte_random_number_generator: RandomNumberGenerator = RandomNumberGenerator.new()
var broken_length_cm: float = 0.0
var broken_poops: Array[Poop] = []
var active_poop: Poop
var poop_reserve: PoopReserveScript = PoopReserveScript.new()


# 返回默认满蓄力距离加上当前腹肌升级后的厘米数，不包含食物临时加成。
static func get_max_charged_push_distance_cm_without_food() -> float:
	return (
		DEFAULT_MAX_CHARGE_PUSH_DISTANCE_PIXELS / Poop.DEFAULT_PIXELS_PER_CM
		+ OrganProgression.get_abdominal_full_charge_bonus_cm()
	)


# 初始化倒计时、长度、金钱显示、Poop 和本轮计时。
func _ready() -> void:
	enter_shop_button.hide()
	qte_random_number_generator.randomize()
	session_start_clog = GameState.clog_progress
	poop_reserve.reset(PlayerStats.get_effective_storage_capacity_cm())
	_update_countdown_label()
	_spawn_poop()
	_update_length_label()
	_update_reserve_label()
	_update_money_earned_label()
	_update_game_progress_ui()
	_update_break_count_label()
	_reset_charge_state()


# 记录本轮有效的鼠标左键按下和松开。
func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return

	var mouse_event: InputEventMouseButton = event
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if mouse_event.pressed:
		if not is_mouse_button_down:
			is_mouse_button_down = true
			_start_mouse_action()
	else:
		is_mouse_button_down = false
		if has_active_mouse_action:
			_release_mouse_action()


# 更新输入、Poop 平滑移动、长度和等待中的最终结算。
func _process(delta: float) -> void:
	if not is_round_active or not is_instance_valid(active_poop):
		return

	if has_active_mouse_action and not is_round_ending:
		_update_held_action(delta)

	if not _is_long_hold_active():
		active_poop.update_movement(delta, poop_move_speed)

	_update_poop_retraction(delta)
	_update_length_label()
	_update_clog_preview()

	if is_round_ending and _is_round_motion_complete():
		_finish_round()


# 每秒减少剩余时间，并在归零时开始等待最后一次移动。
func _on_countdown_timer_timeout() -> void:
	seconds_remaining = maxi(seconds_remaining - 1, 0)
	_update_countdown_label()

	if seconds_remaining <= 0:
		_begin_round_end()


# QTE等待结束后，按当前顺滑度配置并启动一轮QTE。
func _on_qte_wait_timer_timeout() -> void:
	if not _can_run_qte():
		return

	var smoothness: int = PlayerStats.get_effective_smoothness()
	var integrity: int = PlayerStats.get_effective_integrity()
	var required_successes: int = QTERulesScript.get_required_successes(integrity)
	var target_center_count: int = QTERulesScript.get_target_center_count(
		OrganProgression.get_level(OrganProgression.Organ.SPHINCTER)
	)
	current_qte_is_double = required_successes > 1
	qte_bar.configure_qte(
		QTERulesScript.get_pointer_speed(
			smoothness,
			normal_qte_pointer_speed,
			loose_qte_speed_multiplier
		),
		target_center_count,
		required_successes,
		QTERulesScript.uses_faded_display(integrity)
	)
	qte_bar.start_qte()


# QTE成功后保持完整，并重新安排下一次等待。
func _on_qte_bar_qte_succeeded() -> void:
	if not _can_run_qte():
		return

	if current_qte_is_double:
		has_completed_double_qte = true
	current_qte_is_double = false
	_schedule_next_qte()


# QTE失败后夹断当前活动段、生成新段并继续本轮。
func _on_qte_bar_qte_failed() -> void:
	if not _can_run_qte():
		return

	break_count += 1
	current_qte_is_double = false
	_break_active_poop()
	_update_break_count_label()
	_schedule_next_qte()


# 冻结当前实际段、启动掉落，并立即生成新的活动段。
func _break_active_poop() -> void:
	if not is_instance_valid(active_poop):
		return

	_cancel_mouse_action_for_break()
	var segment_length_cm: float = maxf(active_poop.get_length_cm(), 0.0)
	if segment_length_cm > 0.0:
		broken_length_cm += segment_length_cm
		broken_poops.append(active_poop)
		active_poop.start_falling(poop_end_marker.global_position)
	else:
		active_poop.queue_free()

	_spawn_poop()
	_update_length_label()
	_update_clog_preview()


# 夹断时取消当前蓄力，但保留真实按键状态直到玩家松开。
func _cancel_mouse_action_for_break() -> void:
	_reset_charge_state()
	poop_idle_duration = 0.0


# 在允许输入时开始记录一次新的鼠标操作。
func _start_mouse_action() -> void:
	if (
		not is_round_active
		or is_round_ending
		or seconds_remaining <= 0
		or has_active_mouse_action
	):
		return

	_start_round()
	poop_idle_duration = 0.0
	has_active_mouse_action = true
	hold_duration = 0.0
	_update_charge_bar()


# 第一次有效左键输入时启动倒计时和QTE调度。
func _start_round() -> void:
	if has_round_started:
		return

	has_round_started = true
	countdown_timer.start()
	_schedule_next_qte()


# 根据按住时间判定单击或长按，并加入对应推出距离。
func _release_mouse_action() -> void:
	if not has_active_mouse_action:
		return

	var push_pixels: float = click_push_distance
	if hold_duration >= click_max_duration:
		push_pixels = _get_charged_push_distance()

	var pixels_per_cm: float = active_poop.get_pixels_per_cm()
	var requested_cm: float = push_pixels / pixels_per_cm
	var consumed_cm: float = poop_reserve.consume(requested_cm)
	var allowed_push_pixels: float = consumed_cm * pixels_per_cm
	if allowed_push_pixels > 0.0:
		active_poop.push_distance(allowed_push_pixels)
	_update_reserve_label()
	_reset_charge_state()


# 先计算基础长按距离，再按蓄力比例加入腹肌满蓄力奖励并应用食物倍率。
func _get_charged_push_distance() -> float:
	var charge_ratio: float = _get_charge_ratio()
	var base_push_distance: float = lerpf(
		min_charge_push_distance,
		max_charge_push_distance,
		charge_ratio
	)
	var abdominal_bonus_pixels: float = (
		OrganProgression.get_abdominal_full_charge_bonus_cm()
		* active_poop.get_pixels_per_cm()
		* charge_ratio
	)
	var food_charge_multiplier: float = (
		1.0 + float(FoodSystem.get_active_charge_bonus()) * 0.1
	)
	return (base_push_distance + abdominal_bonus_pixels) * food_charge_multiplier


# 累计当前鼠标操作的按住时间，并在最大蓄力时间封顶。
func _update_held_action(delta: float) -> void:
	hold_duration = minf(hold_duration + delta, max_charge_duration)
	_update_charge_bar()


# 返回从长按阈值到最大按住时间之间的蓄力比例。
func _get_charge_ratio() -> float:
	var charge_duration: float = maxf(
		max_charge_duration - click_max_duration,
		0.001
	)
	return clampf(
		(hold_duration - click_max_duration) / charge_duration,
		0.0,
		1.0
	)


# 根据从按下开始的总时间更新0到100的蓄力条。
func _update_charge_bar() -> void:
	var display_ratio: float = clampf(
		hold_duration / maxf(max_charge_duration, 0.001),
		0.0,
		1.0
	)
	charge_bar.value = display_ratio * 100.0


# 清空单次蓄力和输入状态，不影响真实鼠标按键状态。
func _reset_charge_state() -> void:
	has_active_mouse_action = false
	hold_duration = 0.0
	charge_bar.value = 0.0


# 返回当前是否已经进入需要暂停 Poop 移动的有效长按状态。
func _is_long_hold_active() -> bool:
	return (
		has_active_mouse_action
		and not is_round_ending
		and hold_duration >= click_max_duration
	)


# 累计推出完成后的空闲时间，并在允许时持续缩回Poop。
func _update_poop_retraction(delta: float) -> void:
	if not _can_retract_poop():
		poop_idle_duration = 0.0
		return

	poop_idle_duration += delta
	if poop_idle_duration < idle_retract_delay:
		return

	active_poop.retract(delta, poop_retract_speed)


# 返回当前回合和输入状态是否允许Poop开始或继续缩回。
func _can_retract_poop() -> bool:
	return (
		has_round_started
		and is_round_active
		and not is_round_ending
		and not has_settled_round
		and seconds_remaining > 0
		and not has_active_mouse_action
		and not is_mouse_button_down
		and not active_poop.is_moving()
	)


# 更新本轮夹断次数文字。
func _update_break_count_label() -> void:
	break_count_label.text = "BREAKS: %d" % break_count


# 返回当前厕所回合是否允许启动或继续调度QTE。
func _can_run_qte() -> bool:
	return (
		has_round_started
		and is_round_active
		and not is_round_ending
		and seconds_remaining > 0
	)


# 根据顺滑度随机安排下一次QTE等待时间。
func _schedule_next_qte() -> void:
	qte_wait_timer.stop()
	if not _can_run_qte():
		return

	var wait_interval: Vector2 = QTERulesScript.get_wait_interval(
		PlayerStats.get_effective_smoothness(),
		hard_qte_min_interval,
		hard_qte_max_interval,
		normal_qte_min_interval,
		normal_qte_max_interval
	)
	var minimum_interval: float = wait_interval.x
	var maximum_interval: float = wait_interval.y

	var safe_minimum: float = minf(minimum_interval, maximum_interval)
	var safe_maximum: float = maxf(minimum_interval, maximum_interval)
	qte_wait_timer.start(
		qte_random_number_generator.randf_range(
			safe_minimum,
			safe_maximum
		)
	)


# 停止等待并取消当前正在显示的QTE。
func _stop_qte_cycle() -> void:
	qte_wait_timer.stop()
	qte_bar.cancel_qte()
	current_qte_is_double = false


# 倒计时归零时自动释放当前操作，并禁止开始新输入。
func _begin_round_end() -> void:
	if is_round_ending or not is_round_active:
		return

	is_round_ending = true
	poop_idle_duration = 0.0
	countdown_timer.stop()
	_stop_qte_cycle()

	if has_active_mouse_action:
		_release_mouse_action()
	else:
		_reset_charge_state()

	if _is_round_motion_complete():
		_finish_round()


# 将当前剩余秒数更新到倒计时标签。
func _update_countdown_label() -> void:
	countdown_label.text = str(seconds_remaining)


# 更新当前长度或本轮最终长度的文字。
func _update_length_label(show_final_length: bool = false) -> void:
	if show_final_length:
		length_label.text = "Final Length: %.1f cm" % final_length_cm
	elif is_instance_valid(active_poop):
		length_label.text = "Length: %.1f cm" % _get_total_length_cm()
	else:
		length_label.text = "Length: 0.0 cm"


# 更新本轮剩余与最大Poop储备文字。
func _update_reserve_label() -> void:
	reserve_label.text = "RESERVE: %.1f / %.1f cm" % [
		poop_reserve.get_remaining_reserve_cm(),
		poop_reserve.get_max_reserve_cm()
	]


# 更新当前天数、堵塞目标和堵塞条范围。
func _update_game_progress_ui() -> void:
	day_label.text = "DAY %d / %d" % [
		GameState.current_day,
		GameState.MAX_DAYS
	]
	var target_percent: int = roundi(
		GameState.TARGET_CLOG_PROGRESS
		/ GameState.MAX_CLOG_PROGRESS
		* 100.0
	)
	clog_target_label.text = "CLOG TARGET: %d%%" % target_percent
	clog_progress_bar.max_value = GameState.MAX_CLOG_PROGRESS
	_update_clog_preview()


# 根据本轮实时超出长度更新堵塞预览，但不写入永久进度。
func _update_clog_preview() -> void:
	if is_instance_valid(active_poop):
		session_clog_gain = maxf(
			_get_current_clog_length_cm()
			* GameState.CLOG_PROGRESS_PER_CM,
			0.0
		)

	clog_progress_bar.value = clampf(
		session_start_clog + session_clog_gain,
		0.0,
		GameState.MAX_CLOG_PROGRESS
	)


# 返回已断固定长度与当前活动段长度之和。
func _get_total_length_cm() -> float:
	var active_length_cm: float = 0.0
	if is_instance_valid(active_poop):
		active_length_cm = maxf(active_poop.get_length_cm(), 0.0)
	return maxf(broken_length_cm + active_length_cm, 0.0)


# 返回所有已经落定断段的完整长度。
func _get_settled_broken_length_cm() -> float:
	var settled_length_cm: float = 0.0
	for poop_segment: Poop in broken_poops:
		if is_instance_valid(poop_segment) and poop_segment.is_settled():
			settled_length_cm += maxf(poop_segment.get_length_cm(), 0.0)
	return settled_length_cm


# 返回当前用于堵塞预览和结算的长度。
func _get_current_clog_length_cm() -> float:
	var active_excess_length_cm: float = 0.0
	if is_instance_valid(active_poop):
		active_excess_length_cm = maxf(
			active_poop.get_excess_length_cm(),
			0.0
		)
	return _get_settled_broken_length_cm() + active_excess_length_cm


# 返回是否仍有已断段正在执行掉落Tween。
func _has_falling_poops() -> bool:
	for poop_segment: Poop in broken_poops:
		if is_instance_valid(poop_segment) and poop_segment.is_falling():
			return true
	return false


# 返回活动段与所有掉落段是否都已完成本轮运动。
func _is_round_motion_complete() -> bool:
	return (
		is_instance_valid(active_poop)
		and not active_poop.is_moving()
		and not _has_falling_poops()
	)


# 生成新的活动Poop段，并交给它完成顶部对齐。
func _spawn_poop() -> void:
	active_poop = POOP_SCENE.instantiate() as Poop
	add_child(active_poop)
	active_poop.initialize(
		poop_spawn_marker.global_position,
		poop_end_marker.global_position
	)


# 更新厕所中本轮实际获得金钱的文字。
func _update_money_earned_label() -> void:
	money_earned_label.text = "Money Earned: $%d" % money_earned


# 使用最终原始数据完成一次且仅一次的堵塞与金钱结算。
func _settle_round() -> void:
	if has_settled_round:
		return

	has_settled_round = true
	session_clog_gain = maxf(
		_get_current_clog_length_cm()
		* GameState.CLOG_PROGRESS_PER_CM,
		0.0
	)
	GameState.add_clog_progress(session_clog_gain)
	money_earned = Economy.add_poop_value(
		final_length_cm,
		PlayerStats.get_effective_integrity(),
		has_completed_double_qte,
		FoodSystem.get_active_value_multiplier()
	)
	_update_money_earned_label()
	_update_clog_preview()
	FoodSystem.clear_active_foods()


# 结算完成后进入商店场景。
func _on_enter_shop_button_pressed() -> void:
	if is_round_active or not has_settled_round or GameState.is_final_day():
		return

	get_tree().change_scene_to_file(SHOP_SCENE_PATH)


# 第5天显示最终结果，其他天显示商店入口。
func _show_round_destination() -> void:
	if not GameState.is_final_day():
		enter_shop_button.show()
		return

	if GameState.is_clog_target_reached():
		result_label.text = "TOILET CLOGGED!\nTARGET REACHED"
	else:
		result_label.text = "NOT CLOGGED ENOUGH"
	result_label.show()

# 最后一次移动完成后统一结算，并显示商店入口或第5天结果。
func _finish_round() -> void:
	if not is_round_active or not is_round_ending:
		return

	final_length_cm = _get_total_length_cm()
	is_round_active = false
	_update_length_label(true)
	_settle_round()
	_show_round_destination()

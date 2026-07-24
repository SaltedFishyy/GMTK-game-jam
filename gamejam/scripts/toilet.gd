extends Node2D

const POOP_SCENE: PackedScene = preload("res://scenes/poop.tscn")
const PoopScript = preload("res://scripts/poop.gd")
const QTEBarScript = preload("res://scripts/components/qte_bar.gd")
const SHOP_SCENE_PATH: String = "res://scenes/shop.tscn"
const STARTING_SECONDS: int = 10

@export_range(1.0, 1000.0, 1.0, "suffix:px/s") var poop_move_speed: float = 400.0
@export_range(0.05, 1.0, 0.05, "suffix:s") var click_max_duration: float = 0.3
@export_range(1.0, 200.0, 1.0, "suffix:px") var click_push_distance: float = 20.0
@export_range(0.1, 3.0, 0.1, "suffix:s") var max_charge_duration: float = 1.5
@export_range(1.0, 300.0, 1.0, "suffix:px") var min_charge_push_distance: float = 40.0
@export_range(1.0, 300.0, 1.0, "suffix:px") var max_charge_push_distance: float = 120.0
@export_range(0.0, 10.0, 0.1) var smoothness: float = 6.0
@export_range(0.1, 10.0, 0.1, "suffix:s") var hard_qte_min_interval: float = 1.0
@export_range(0.1, 10.0, 0.1, "suffix:s") var hard_qte_max_interval: float = 3.0
@export_range(0.1, 10.0, 0.1, "suffix:s") var normal_qte_min_interval: float = 2.0
@export_range(0.1, 10.0, 0.1, "suffix:s") var normal_qte_max_interval: float = 5.0
@export_range(10.0, 1200.0, 10.0, "suffix:px/s") var normal_qte_pointer_speed: float = 400.0
@export_range(1.0, 3.0, 0.1) var loose_qte_speed_multiplier: float = 1.5

@onready var countdown_label: Label = $CountdownLabel
@onready var length_label: Label = $LengthLabel
@onready var money_earned_label: Label = $MoneyEarnedLabel
@onready var total_money_label: Label = $TotalMoneyLabel
@onready var day_label: Label = $DayLabel
@onready var clog_progress_bar: ProgressBar = $ClogProgressBar
@onready var smoothness_bar: ProgressBar = $SmoothnessBar
@onready var smoothness_label: Label = $SmoothnessLabel
@onready var break_count_label: Label = $BreakCountLabel
@onready var qte_bar: QTEBarScript = $QTEBar
@onready var qte_wait_timer: Timer = $QTEWaitTimer
@onready var enter_shop_button: Button = $EnterShopButton
@onready var countdown_timer: Timer = $CountdownTimer
@onready var poop_spawn_marker: Marker2D = $PoopSpawnMarker
@onready var poop_end_marker: Marker2D = $PoopEndMarker

var seconds_remaining: int = STARTING_SECONDS
var has_spawned_poop: bool = false
var has_round_started: bool = false
var is_round_active: bool = true
var final_length_cm: float = 0.0
var money_earned: int = 0
var has_settled_round: bool = false
var is_round_ending: bool = false
var is_mouse_button_down: bool = false
var has_active_mouse_action: bool = false
var hold_duration: float = 0.0
var session_start_clog: float = 0.0
var session_clog_gain: float = 0.0
var break_count: int = 0
var qte_random_number_generator: RandomNumberGenerator = RandomNumberGenerator.new()
var poop_instance: PoopScript


# 初始化倒计时、长度、金钱显示、Poop 和本轮计时。
func _ready() -> void:
	enter_shop_button.hide()
	qte_random_number_generator.randomize()
	session_start_clog = GameState.clog_progress
	_update_countdown_label()
	_spawn_poop()
	_update_length_label()
	_update_money_labels()
	_update_game_progress_ui()
	_update_smoothness_ui()
	_update_break_count_label()


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
	if not is_round_active or not is_instance_valid(poop_instance):
		return

	if has_active_mouse_action and not is_round_ending:
		_update_held_action(delta)

	if not _is_long_hold_active():
		poop_instance.update_movement(delta, poop_move_speed)

	_update_length_label()
	_update_clog_preview()
	_update_smoothness_ui()

	if is_round_ending and not poop_instance.is_moving():
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

	var pointer_speed: float = normal_qte_pointer_speed
	if smoothness >= 8.0:
		pointer_speed *= loose_qte_speed_multiplier

	qte_bar.configure_pointer_speed(pointer_speed)
	qte_bar.start_qte()


# QTE成功后保持完整，并重新安排下一次等待。
func _on_qte_bar_qte_succeeded() -> void:
	if not _can_run_qte():
		return

	_schedule_next_qte()


# QTE失败后增加一次夹断，并重新安排下一次等待。
func _on_qte_bar_qte_failed() -> void:
	if not _can_run_qte():
		return

	break_count += 1
	_update_break_count_label()
	_schedule_next_qte()


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
	has_active_mouse_action = true
	hold_duration = 0.0


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
		push_pixels = lerpf(
			min_charge_push_distance,
			max_charge_push_distance,
			_get_charge_ratio()
		)

	poop_instance.push_distance(push_pixels)
	has_active_mouse_action = false


# 累计当前鼠标操作的按住时间。
func _update_held_action(delta: float) -> void:
	hold_duration += delta


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


# 返回当前是否已经进入需要暂停 Poop 移动的有效长按状态。
func _is_long_hold_active() -> bool:
	return (
		has_active_mouse_action
		and not is_round_ending
		and hold_duration >= click_max_duration
	)


# 更新顺滑度数值与当前状态文字。
func _update_smoothness_ui() -> void:
	smoothness = clampf(smoothness, 0.0, 10.0)
	smoothness_bar.value = smoothness

	if smoothness <= 4.0:
		smoothness_label.text = "SMOOTHNESS: HARD"
	elif smoothness <= 7.0:
		smoothness_label.text = "SMOOTHNESS: NORMAL"
	else:
		smoothness_label.text = "SMOOTHNESS: TOO LOOSE"


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

	var minimum_interval: float = normal_qte_min_interval
	var maximum_interval: float = normal_qte_max_interval
	if smoothness <= 4.0:
		minimum_interval = hard_qte_min_interval
		maximum_interval = hard_qte_max_interval

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


# 倒计时归零时自动释放当前操作，并禁止开始新输入。
func _begin_round_end() -> void:
	if is_round_ending or not is_round_active:
		return

	is_round_ending = true
	countdown_timer.stop()
	_stop_qte_cycle()

	if has_active_mouse_action:
		_release_mouse_action()

	if not poop_instance.is_moving():
		_finish_round()


# 将当前剩余秒数更新到倒计时标签。
func _update_countdown_label() -> void:
	countdown_label.text = str(seconds_remaining)


# 更新当前长度或本轮最终长度的文字。
func _update_length_label(show_final_length: bool = false) -> void:
	if show_final_length:
		length_label.text = "Final Length: %.1f cm" % final_length_cm
	elif is_instance_valid(poop_instance):
		length_label.text = "Length: %.1f cm" % poop_instance.get_length_cm()
	else:
		length_label.text = "Length: 0.0 cm"


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
	clog_progress_bar.max_value = GameState.MAX_CLOG_PROGRESS
	_update_clog_preview()


# 根据本轮实时超出长度更新堵塞预览，但不写入永久进度。
func _update_clog_preview() -> void:
	if is_instance_valid(poop_instance):
		session_clog_gain = maxf(
			poop_instance.get_excess_length_cm()
			* GameState.CLOG_PROGRESS_PER_CM,
			0.0
		)

	clog_progress_bar.value = clampf(
		session_start_clog + session_clog_gain,
		0.0,
		GameState.MAX_CLOG_PROGRESS
	)


# 生成一次 Poop，并交给它完成起点对齐和终点计算。
func _spawn_poop() -> void:
	if has_spawned_poop:
		return

	has_spawned_poop = true
	poop_instance = POOP_SCENE.instantiate() as PoopScript
	add_child(poop_instance)
	poop_instance.initialize(
		poop_spawn_marker.global_position,
		poop_end_marker.global_position
	)


# 更新本轮获得金钱和当前总金钱的文字。
func _update_money_labels() -> void:
	money_earned_label.text = "Money Earned: $%d" % money_earned
	total_money_label.text = "Total Money: $%d" % Economy.total_money


# 使用最终原始数据完成一次且仅一次的堵塞与金钱结算。
func _settle_round() -> void:
	if has_settled_round:
		return

	has_settled_round = true
	session_clog_gain = maxf(
		poop_instance.get_excess_length_cm()
		* GameState.CLOG_PROGRESS_PER_CM,
		0.0
	)
	GameState.add_clog_progress(session_clog_gain)
	money_earned = Economy.add_poop_value(final_length_cm, break_count)
	_update_money_labels()
	_update_clog_preview()


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




# 最后一次移动完成后统一结算，并显示商店入口或第5天结果。
func _finish_round() -> void:
	if not is_round_active or not is_round_ending:
		return

	final_length_cm = maxf(poop_instance.get_length_cm(), 0.0)
	is_round_active = false
	_update_length_label(true)
	_settle_round()
	_show_round_destination()

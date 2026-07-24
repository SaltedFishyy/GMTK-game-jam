extends Node2D

const POOP_SCENE: PackedScene = preload("res://scenes/poop.tscn")
const PoopScript = preload("res://scripts/poop.gd")
const SHOP_SCENE_PATH: String = "res://scenes/shop.tscn"
const STARTING_SECONDS: int = 10

@export_range(1.0, 1000.0, 1.0, "suffix:px/s") var poop_move_speed: float = 120.0
@export_range(0.05, 1.0, 0.05, "suffix:s") var click_max_duration: float = 0.3
@export_range(1.0, 200.0, 1.0, "suffix:px") var click_push_distance: float = 20.0
@export_range(0.1, 3.0, 0.1, "suffix:s") var max_charge_duration: float = 1.5
@export_range(1.0, 300.0, 1.0, "suffix:px") var min_charge_push_distance: float = 40.0
@export_range(1.0, 300.0, 1.0, "suffix:px") var max_charge_push_distance: float = 120.0
@export_range(1.0, 1000.0, 1.0) var max_stamina: float = 100.0
@export_range(0.0, 100.0, 1.0) var click_stamina_cost: float = 5.0
@export_range(0.0, 200.0, 1.0, "suffix:/s") var hold_stamina_drain_per_second: float = 30.0
@export_range(0.1, 10.0, 0.1, "suffix:s") var stamina_recovery_duration: float = 1.0

@onready var countdown_label: Label = $CountdownLabel
@onready var length_label: Label = $LengthLabel
@onready var money_earned_label: Label = $MoneyEarnedLabel
@onready var total_money_label: Label = $TotalMoneyLabel
@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var day_label: Label = $DayLabel
@onready var clog_target_label: Label = $ClogTargetLabel
@onready var clog_progress_bar: ProgressBar = $ClogProgressBar
@onready var result_label: Label = $ResultLabel
@onready var enter_shop_button: Button = $EnterShopButton
@onready var countdown_timer: Timer = $CountdownTimer
@onready var poop_spawn_marker: Marker2D = $PoopSpawnMarker
@onready var poop_end_marker: Marker2D = $PoopEndMarker

var seconds_remaining: int = STARTING_SECONDS
var has_spawned_poop: bool = false
var is_round_active: bool = true
var final_length_cm: float = 0.0
var money_earned: int = 0
var has_settled_round: bool = false
var is_round_ending: bool = false
var is_mouse_button_down: bool = false
var has_active_mouse_action: bool = false
var hold_duration: float = 0.0
var current_stamina: float = 0.0
var session_start_clog: float = 0.0
var session_clog_gain: float = 0.0
var poop_instance: PoopScript


# 初始化倒计时、体力、长度、金钱显示、Poop 和本轮计时。
func _ready() -> void:
	enter_shop_button.hide()
	result_label.hide()
	session_start_clog = GameState.clog_progress
	current_stamina = maxf(max_stamina, 0.0)
	_update_stamina_bar()
	_update_countdown_label()
	_spawn_poop()
	_update_length_label()
	_update_money_labels()
	_update_game_progress_ui()
	countdown_timer.start()


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


# 更新输入、体力、Poop 平滑移动、长度和等待中的最终结算。
func _process(delta: float) -> void:
	if not is_round_active or not is_instance_valid(poop_instance):
		return

	if has_active_mouse_action and not is_round_ending:
		_update_held_action(delta)

	if not _is_long_hold_active():
		poop_instance.update_movement(delta, poop_move_speed)

	if _can_recover_stamina():
		_recover_stamina(delta)

	_update_stamina_bar()
	_update_length_label()
	_update_clog_preview()

	if is_round_ending and not poop_instance.is_moving():
		_finish_round()


# 每秒减少剩余时间，并在归零时开始等待最后一次移动。
func _on_countdown_timer_timeout() -> void:
	seconds_remaining = maxi(seconds_remaining - 1, 0)
	_update_countdown_label()

	if seconds_remaining <= 0:
		_begin_round_end()


# 在允许输入时开始记录一次新的鼠标操作。
func _start_mouse_action() -> void:
	if (
		not is_round_active
		or is_round_ending
		or seconds_remaining <= 0
		or has_active_mouse_action
		or current_stamina < click_stamina_cost
	):
		return

	has_active_mouse_action = true
	hold_duration = 0.0


# 根据按住时间判定单击或长按，扣除对应体力并加入推出距离。
func _release_mouse_action() -> void:
	if not has_active_mouse_action:
		return

	var push_pixels: float = click_push_distance
	if hold_duration < click_max_duration:
		current_stamina = clampf(
			current_stamina - click_stamina_cost,
			0.0,
			maxf(max_stamina, 0.0)
		)
	else:
		push_pixels = lerpf(
			min_charge_push_distance,
			max_charge_push_distance,
			_get_charge_ratio()
		)

	poop_instance.push_distance(push_pixels)
	has_active_mouse_action = false
	_update_stamina_bar()


# 累计按住时间，并在进入长按后持续消耗体力。
func _update_held_action(delta: float) -> void:
	var previous_hold_duration: float = hold_duration
	hold_duration += delta

	if hold_duration < click_max_duration:
		return

	var drain_start: float = maxf(previous_hold_duration, click_max_duration)
	var stamina_drain_time: float = maxf(hold_duration - drain_start, 0.0)
	current_stamina = clampf(
		current_stamina - hold_stamina_drain_per_second * stamina_drain_time,
		0.0,
		maxf(max_stamina, 0.0)
	)

	if is_zero_approx(current_stamina):
		current_stamina = 0.0
		_release_mouse_action()


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


# 返回当前是否可以在鼠标松开后恢复体力。
func _can_recover_stamina() -> bool:
	return (
		not is_mouse_button_down
		and not has_active_mouse_action
		and not is_round_ending
		and current_stamina < max_stamina
	)


# 使用基于 delta 的固定速度恢复体力。
func _recover_stamina(delta: float) -> void:
	var safe_max_stamina: float = maxf(max_stamina, 0.0)
	var recovery_rate: float = (
		safe_max_stamina / maxf(stamina_recovery_duration, 0.001)
	)
	current_stamina = move_toward(
		current_stamina,
		safe_max_stamina,
		recovery_rate * delta
	)


# 将当前体力同步到始终可见的 StaminaBar。
func _update_stamina_bar() -> void:
	var safe_max_stamina: float = maxf(max_stamina, 0.0)
	current_stamina = clampf(current_stamina, 0.0, safe_max_stamina)
	stamina_bar.max_value = maxf(safe_max_stamina, 0.001)
	stamina_bar.value = current_stamina


# 倒计时归零时自动释放当前操作，并禁止开始新输入。
func _begin_round_end() -> void:
	if is_round_ending or not is_round_active:
		return

	is_round_ending = true
	countdown_timer.stop()

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
	clog_target_label.text = "CLOG TARGET: %d%%" % target_percent
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
	money_earned = Economy.add_poop_value(final_length_cm)
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

	if GameState.is_clog_target_reached():
		result_label.text = "TOILET CLOGGED!\nTARGET REACHED"
	else:
		result_label.text = "NOT CLOGGED ENOUGH"
	result_label.show()


# 最后一次移动完成后统一结算，并显示商店入口或第5天结果。
func _finish_round() -> void:
	if not is_round_active or not is_round_ending:
		return

	final_length_cm = maxf(poop_instance.get_length_cm(), 0.0)
	is_round_active = false
	_update_stamina_bar()
	_update_length_label(true)
	_settle_round()
	_show_round_destination()

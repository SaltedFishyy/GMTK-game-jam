class_name QTEBar
extends Control

signal qte_succeeded
signal qte_failed

@export_range(10.0, 1200.0, 10.0, "suffix:px/s") var pointer_speed: float = 400.0
@export_range(10.0, 500.0, 5.0, "suffix:px") var target_area_width: float = 120.0
@export_range(0.1, 1.0, 0.05) var faded_min_alpha: float = 0.4
@export_range(0.1, 10.0, 0.1, "suffix:/s") var faded_pulse_speed: float = 3.0

@onready var bar_background: ColorRect = $BarBackground
@onready var target_area: ColorRect = $BarBackground/TargetArea
@onready var pointer: ColorRect = $BarBackground/Pointer
@onready var progress_label: Label = $ProgressLabel

var random_number_generator: RandomNumberGenerator = RandomNumberGenerator.new()
var pointer_direction: float = 1.0
var is_active: bool = false
var configured_pointer_speed: float = 400.0
var configured_target_width_multiplier: float = 1.0
var configured_required_successes: int = 1
var configured_faded_display: bool = false
var active_pointer_speed: float = 400.0
var active_target_width_multiplier: float = 1.0
var active_required_successes: int = 1
var active_faded_display: bool = false
var completed_successes: int = 0
var fade_elapsed: float = 0.0


# 初始化随机数生成器，并让未激活的组件保持隐藏。
func _ready() -> void:
	random_number_generator.randomize()
	configured_pointer_speed = pointer_speed
	active_pointer_speed = pointer_speed
	progress_label.hide()
	modulate.a = 1.0
	hide()
	set_process(false)


# 配置下一次QTE，当前已经激活的QTE不会被改变。
func configure_qte(
	speed: float,
	target_width_multiplier: float,
	required_successes: int,
	use_faded_display: bool
) -> void:
	configured_pointer_speed = maxf(speed, 0.0)
	configured_target_width_multiplier = maxf(target_width_multiplier, 0.01)
	configured_required_successes = maxi(required_successes, 1)
	configured_faded_display = use_faded_display


# 激活一次新的QTE，并锁定配置与随机目标区域。
func start_qte() -> void:
	if is_active:
		return

	active_pointer_speed = configured_pointer_speed
	active_target_width_multiplier = configured_target_width_multiplier
	active_required_successes = configured_required_successes
	active_faded_display = configured_faded_display
	completed_successes = 0
	fade_elapsed = 0.0
	modulate.a = 1.0
	_randomize_target_position()
	_update_progress_label()
	pointer.position = Vector2.ZERO
	pointer_direction = 1.0
	is_active = true
	show()
	set_process(true)


# 在判定条的有效范围内随机放置目标区域。
func _randomize_target_position() -> void:
	var available_width: float = bar_background.size.x
	var actual_target_width: float = clampf(
		target_area_width * active_target_width_multiplier,
		1.0,
		available_width
	)
	var target_x: float = random_number_generator.randf_range(
		0.0,
		available_width - actual_target_width
	)

	target_area.position = Vector2(target_x, 0.0)
	target_area.size = Vector2(actual_target_width, bar_background.size.y)


# 取消当前QTE，不发送成功或失败信号。
func cancel_qte() -> void:
	if not is_active:
		return

	_end_qte()


# 安全设置指针速度，不暴露或操作组件内部节点。
func configure_pointer_speed(speed: float) -> void:
	configured_pointer_speed = maxf(speed, 0.0)


# 让指针在判定条左右边界之间持续往返。
func _process(delta: float) -> void:
	if active_faded_display:
		fade_elapsed += delta
		var pulse_weight: float = (sin(fade_elapsed * faded_pulse_speed) + 1.0) * 0.5
		modulate.a = lerpf(clampf(faded_min_alpha, 0.1, 1.0), 1.0, pulse_weight)

	var right_limit: float = maxf(
		bar_background.size.x - pointer.size.x,
		0.0
	)
	var next_x: float = (
		pointer.position.x
		+ active_pointer_speed * pointer_direction * delta
	)

	if next_x >= right_limit:
		next_x = right_limit
		pointer_direction = -1.0
	elif next_x <= 0.0:
		next_x = 0.0
		pointer_direction = 1.0

	pointer.position.x = next_x


# 仅在QTE激活时响应一次空格键判定。
func _unhandled_input(event: InputEvent) -> void:
	if (
		not is_active
		or not event is InputEventKey
		or not event.pressed
		or event.echo
	):
		return

	var key_event: InputEventKey = event
	if key_event.keycode != KEY_SPACE:
		return

	get_viewport().set_input_as_handled()
	_judge_pointer_position()


# 根据指针中心是否位于目标区域内处理当前一次判定。
func _judge_pointer_position() -> void:
	var pointer_center_x: float = pointer.position.x + pointer.size.x * 0.5
	var target_left: float = target_area.position.x
	var target_right: float = target_left + target_area.size.x
	var succeeded: bool = (
		pointer_center_x >= target_left
		and pointer_center_x <= target_right
	)

	if succeeded:
		completed_successes += 1
		if completed_successes < active_required_successes:
			_randomize_target_position()
			_update_progress_label()
			pointer.position.x = 0.0
			pointer_direction = 1.0
			return

		_end_qte()
		qte_succeeded.emit()
	else:
		_end_qte()
		qte_failed.emit()


# 更新双重QTE的当前判定进度。
func _update_progress_label() -> void:
	if active_required_successes <= 1:
		progress_label.hide()
		return

	progress_label.text = "%d / %d" % [
		completed_successes + 1,
		active_required_successes
	]
	progress_label.show()


# 结束并隐藏QTE，同时恢复不会影响下一轮的显示状态。
func _end_qte() -> void:
	is_active = false
	set_process(false)
	progress_label.hide()
	modulate.a = 1.0
	hide()

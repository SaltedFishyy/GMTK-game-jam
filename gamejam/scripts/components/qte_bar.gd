class_name QTEBar
extends Control

signal qte_succeeded
signal qte_failed

const MIN_TARGET_CENTER_COUNT: int = 3
const MID_TARGET_CENTER_COUNT: int = 5
const MAX_TARGET_CENTER_COUNT: int = 7

@export_range(10.0, 1200.0, 10.0, "suffix:px/s") var pointer_speed: float = 400.0
@export_range(0.1, 1.0, 0.05) var faded_min_alpha: float = 0.4
@export_range(0.1, 10.0, 0.1, "suffix:/s") var faded_pulse_speed: float = 3.0

var random_number_generator: RandomNumberGenerator = RandomNumberGenerator.new()
var pointer_direction: float = 1.0
var is_active: bool = false
var configured_pointer_speed: float = 400.0
var configured_target_center_count: int = MIN_TARGET_CENTER_COUNT
var configured_required_successes: int = 1
var configured_faded_display: bool = false
var active_pointer_speed: float = 400.0
var active_target_center_count: int = MIN_TARGET_CENTER_COUNT
var active_required_successes: int = 1
var active_faded_display: bool = false
var completed_successes: int = 0
var fade_elapsed: float = 0.0

@onready var track: Control = $Track
@onready var target_area: HBoxContainer = $Track/TargetArea
@onready var left_cap: TextureRect = $Track/TargetArea/LeftCap
@onready var center_cells: Array[TextureRect] = [
	$Track/TargetArea/Center1,
	$Track/TargetArea/Center2,
	$Track/TargetArea/Center3,
	$Track/TargetArea/Center4,
	$Track/TargetArea/Center5,
	$Track/TargetArea/Center6,
	$Track/TargetArea/Center7,
]
@onready var pointer: TextureRect = $Track/Pointer
@onready var progress_label: Label = $ProgressLabel


# 初始化随机数生成器，并让未激活的组件保持隐藏。
func _ready() -> void:
	random_number_generator.randomize()
	configured_pointer_speed = pointer_speed
	active_pointer_speed = pointer_speed
	_set_target_center_count(MIN_TARGET_CENTER_COUNT)
	progress_label.hide()
	modulate.a = 1.0
	hide()
	set_process(false)


# 配置下一次QTE；当前已经激活的QTE不会被改变。
func configure_qte(
	speed: float,
	target_center_count: int,
	required_successes: int,
	use_faded_display: bool
) -> void:
	configured_pointer_speed = maxf(speed, 0.0)
	configured_target_center_count = _normalize_target_center_count(target_center_count)
	configured_required_successes = maxi(required_successes, 1)
	configured_faded_display = use_faded_display


# 激活一次新QTE，并锁定配置与随机目标区域。
func start_qte() -> void:
	if is_active:
		return

	active_pointer_speed = configured_pointer_speed
	active_target_center_count = configured_target_center_count
	active_required_successes = configured_required_successes
	active_faded_display = configured_faded_display
	completed_successes = 0
	fade_elapsed = 0.0
	modulate.a = 1.0
	_set_target_center_count(active_target_center_count)
	_randomize_target_position()
	_update_progress_label()
	pointer.position.x = 0.0
	pointer_direction = 1.0
	is_active = true
	show()
	set_process(true)


# 将目标按单格宽度随机放在MissArea内，确保整组拼接纹理不会越界。
func _randomize_target_position() -> void:
	var cell_width: float = left_cap.size.x
	var target_cell_count: int = active_target_center_count + 2
	var maximum_start_column: int = maxi(MAX_TARGET_CENTER_COUNT + 2 - target_cell_count, 0)
	var start_column: int = random_number_generator.randi_range(0, maximum_start_column)

	target_area.position = Vector2(float(start_column) * cell_width, 0.0)
	target_area.size = Vector2(float(target_cell_count) * cell_width, track.size.y)


# 取消当前QTE，不发送成功或失败信号。
func cancel_qte() -> void:
	if not is_active:
		return

	_end_qte()


# 让指针完整保持在MissArea左右边界之间持续往返。
func _process(delta: float) -> void:
	if active_faded_display:
		fade_elapsed += delta
		var pulse_weight: float = (sin(fade_elapsed * faded_pulse_speed) + 1.0) * 0.5
		modulate.a = lerpf(clampf(faded_min_alpha, 0.1, 1.0), 1.0, pulse_weight)

	var right_limit: float = maxf(track.size.x - pointer.size.x, 0.0)
	var next_x: float = pointer.position.x + active_pointer_speed * pointer_direction * delta

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


# 根据指针中心是否位于完整拼接目标区域内处理当前判定。
func _judge_pointer_position() -> void:
	var pointer_center_x: float = pointer.position.x + pointer.size.x * 0.5
	var target_left: float = target_area.position.x
	var target_right: float = target_left + target_area.size.x
	var succeeded: bool = pointer_center_x >= target_left and pointer_center_x <= target_right

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


# 控制七个Center格的可见数量；隐藏格不会参与HBoxContainer布局。
func _set_target_center_count(center_count: int) -> void:
	for index: int in center_cells.size():
		center_cells[index].visible = index < center_count


# 将外部配置限制为HIGH、MID、LOW对应的3、5、7格。
func _normalize_target_center_count(center_count: int) -> int:
	if center_count <= MIN_TARGET_CENTER_COUNT:
		return MIN_TARGET_CENTER_COUNT
	if center_count <= MID_TARGET_CENTER_COUNT:
		return MID_TARGET_CENTER_COUNT
	return MAX_TARGET_CENTER_COUNT


# 更新双重QTE的当前判定进度。
func _update_progress_label() -> void:
	if active_required_successes <= 1:
		progress_label.hide()
		return

	progress_label.text = "%d / %d" % [completed_successes + 1, active_required_successes]
	progress_label.show()


# 结束并隐藏QTE，同时恢复不会影响下一轮的显示状态。
func _end_qte() -> void:
	is_active = false
	set_process(false)
	progress_label.hide()
	modulate.a = 1.0
	hide()

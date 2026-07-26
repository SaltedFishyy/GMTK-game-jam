class_name QTEBar
extends Control

signal qte_succeeded
signal qte_failed

const MIN_TARGET_CENTER_COUNT: int = 3
const MID_TARGET_CENTER_COUNT: int = 5
const MAX_TARGET_CENTER_COUNT: int = 7
const VISUAL_SCALE: float = 0.25
const CELL_WIDTH: float = 128.0
const TRACK_HEIGHT: float = 160.0
const VISIBLE_WINDOW_WIDTH: float = 1152.0
const TOTAL_TRACK_CELL_COUNT: int = 45
const MIN_MISS_CELL_COUNT: int = 9

@export_range(10.0, 1200.0, 10.0, "suffix:px/s") var track_speed: float = 400.0
@export_range(0.1, 1.0, 0.05) var faded_min_alpha: float = 0.4
@export_range(0.1, 10.0, 0.1, "suffix:/s") var faded_pulse_speed: float = 3.0

var random_number_generator: RandomNumberGenerator = RandomNumberGenerator.new()
var is_active: bool = false
var configured_track_speed: float = 400.0
var configured_target_center_count: int = MIN_TARGET_CENTER_COUNT
var configured_required_successes: int = 1
var configured_faded_display: bool = false
var active_track_speed: float = 400.0
var active_target_center_count: int = MIN_TARGET_CENTER_COUNT
var active_required_successes: int = 1
var active_faded_display: bool = false
var completed_successes: int = 0
var fade_elapsed: float = 0.0

@onready var moving_track: Control = $VisualRoot/VisibleWindow/MovingTrack
@onready var miss_before: TextureRect = $VisualRoot/VisibleWindow/MovingTrack/MissBefore
@onready var target_area: HBoxContainer = $VisualRoot/VisibleWindow/MovingTrack/TargetArea
@onready var center_cells: Array[TextureRect] = [
	$VisualRoot/VisibleWindow/MovingTrack/TargetArea/Center1,
	$VisualRoot/VisibleWindow/MovingTrack/TargetArea/Center2,
	$VisualRoot/VisibleWindow/MovingTrack/TargetArea/Center3,
	$VisualRoot/VisibleWindow/MovingTrack/TargetArea/Center4,
	$VisualRoot/VisibleWindow/MovingTrack/TargetArea/Center5,
	$VisualRoot/VisibleWindow/MovingTrack/TargetArea/Center6,
	$VisualRoot/VisibleWindow/MovingTrack/TargetArea/Center7,
]
@onready var miss_after: TextureRect = $VisualRoot/VisibleWindow/MovingTrack/MissAfter
@onready var pointer: TextureRect = $VisualRoot/Pointer
@onready var progress_label: Label = $ProgressLabel


# 初始化随机数生成器，并让未激活的组件保持隐藏。
func _ready() -> void:
	random_number_generator.randomize()
	configured_track_speed = track_speed
	active_track_speed = track_speed
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
	configured_track_speed = maxf(speed, 0.0)
	configured_target_center_count = _normalize_target_center_count(target_center_count)
	configured_required_successes = maxi(required_successes, 1)
	configured_faded_display = use_faded_display


# 激活一次新QTE，并锁定配置与第一趟随机轨道。
func start_qte() -> void:
	if is_active:
		return

	active_track_speed = configured_track_speed
	active_target_center_count = configured_target_center_count
	active_required_successes = configured_required_successes
	active_faded_display = configured_faded_display
	completed_successes = 0
	fade_elapsed = 0.0
	modulate.a = 1.0
	_prepare_track_pass()
	_update_progress_label()
	is_active = true
	show()
	set_process(true)


# 按单格随机Target位置，确保它前后都有至少一整个窗口宽度的Miss区域。
func _prepare_track_pass() -> void:
	_set_target_center_count(active_target_center_count)

	var target_cell_count: int = active_target_center_count + 2
	var maximum_before_count: int = (
		TOTAL_TRACK_CELL_COUNT - target_cell_count - MIN_MISS_CELL_COUNT
	)
	var before_cell_count: int = random_number_generator.randi_range(
		MIN_MISS_CELL_COUNT,
		maximum_before_count
	)
	var after_cell_count: int = TOTAL_TRACK_CELL_COUNT - before_cell_count - target_cell_count
	var before_width: float = float(before_cell_count) * CELL_WIDTH
	var target_width: float = float(target_cell_count) * CELL_WIDTH
	var after_width: float = float(after_cell_count) * CELL_WIDTH

	miss_before.position = Vector2.ZERO
	miss_before.size = Vector2(before_width, TRACK_HEIGHT)
	target_area.position = Vector2(before_width, 0.0)
	target_area.size = Vector2(target_width, TRACK_HEIGHT)
	miss_after.position = Vector2(before_width + target_width, 0.0)
	miss_after.size = Vector2(after_width, TRACK_HEIGHT)
	moving_track.position = Vector2(VISIBLE_WINDOW_WIDTH, 0.0)


# 取消当前QTE，不发送成功或失败信号。
func cancel_qte() -> void:
	if not is_active:
		return

	_end_qte()


# 让超长轨道单向向左通过固定Pointer，并在完全离场时自动失败。
func _process(delta: float) -> void:
	if active_faded_display:
		fade_elapsed += delta
		var pulse_weight: float = (sin(fade_elapsed * faded_pulse_speed) + 1.0) * 0.5
		modulate.a = lerpf(clampf(faded_min_alpha, 0.1, 1.0), 1.0, pulse_weight)

	var local_track_speed: float = active_track_speed / VISUAL_SCALE
	moving_track.position.x -= local_track_speed * delta
	var track_width: float = float(TOTAL_TRACK_CELL_COUNT) * CELL_WIDTH
	if moving_track.position.x + track_width < 0.0:
		_fail_qte()


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


# 根据固定Pointer中心是否位于当前Target全局水平范围内处理判定。
func _judge_pointer_position() -> void:
	var pointer_rect: Rect2 = pointer.get_global_rect()
	var target_rect: Rect2 = target_area.get_global_rect()
	var pointer_center_x: float = pointer_rect.get_center().x
	var succeeded: bool = (
		pointer_center_x >= target_rect.position.x
		and pointer_center_x <= target_rect.end.x
	)

	if not succeeded:
		_fail_qte()
		return

	completed_successes += 1
	if completed_successes < active_required_successes:
		_prepare_track_pass()
		_update_progress_label()
		return

	_end_qte()
	qte_succeeded.emit()


# 结束当前QTE并确保失败信号只发出一次。
func _fail_qte() -> void:
	if not is_active:
		return

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

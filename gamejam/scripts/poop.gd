class_name Poop
extends Node2D

signal fall_completed

enum SegmentState {
	ACTIVE,
	FALLING,
	SETTLED,
}

@export_range(0.0, 3.0, 0.05, "suffix:s") var fall_duration: float = 0.5

var clog_threshold_y: float = 0.0
var movement_target_length_pixels: float = 0.0
var segment_state: SegmentState = SegmentState.ACTIVE
var is_initialized: bool = false
var fall_tween: Tween

@onready var visuals: Node2D = $Visuals
@onready var body: Sprite2D = $Visuals/Body
@onready var top_cap: Sprite2D = $Visuals/TopCap
@onready var bottom_cap: Sprite2D = $Visuals/BottomCap
@onready var top_marker: Marker2D = $TopMarker
@onready var bottom_marker: Marker2D = $BottomMarker


# 将活动段顶部对齐出生点，并初始化为0长度。
func initialize(spawn_position: Vector2, clog_threshold_position: Vector2) -> void:
	global_position += spawn_position - top_marker.global_position
	clog_threshold_y = clog_threshold_position.y
	movement_target_length_pixels = 0.0
	segment_state = SegmentState.ACTIVE
	_set_length_pixels(0.0)
	is_initialized = true


# 将一次推出距离沿Y轴累加到当前活动段目标长度。
func push_distance(distance_pixels: float) -> void:
	if (
		not is_initialized
		or segment_state != SegmentState.ACTIVE
		or distance_pixels <= 0.0
	):
		return

	movement_target_length_pixels += distance_pixels


# 让BottomMarker平滑追赶当前累计的目标长度。
func update_movement(delta: float, move_speed: float) -> void:
	if not is_initialized or segment_state != SegmentState.ACTIVE or not is_moving():
		return

	var next_length: float = move_toward(
		_get_length_pixels(),
		movement_target_length_pixels,
		maxf(move_speed, 0.0) * delta
	)
	_set_length_pixels(next_length)


# 将活动段的推出目标锁定为当前实际长度，供回合立即结束时停止后续运动。
func freeze_at_current_length() -> void:
	if not is_initialized or segment_state != SegmentState.ACTIVE:
		return
	movement_target_length_pixels = _get_length_pixels()


# 让活动段平滑缩短，并同步唯一的长度目标。
func retract(delta: float, retract_speed: float) -> void:
	if (
		not is_initialized
		or segment_state != SegmentState.ACTIVE
		or is_moving()
	):
		return

	var current_length: float = _get_length_pixels()
	if is_zero_approx(current_length):
		return

	var next_length: float = move_toward(
		current_length,
		0.0,
		maxf(retract_speed, 0.0) * delta
	)
	_set_length_pixels(next_length)
	movement_target_length_pixels = next_length


# 冻结当前实际长度，并让切断端从出生点下落到指定位置。
func start_falling(end_position: Vector2) -> void:
	if not is_initialized or segment_state != SegmentState.ACTIVE:
		return

	movement_target_length_pixels = _get_length_pixels()
	top_cap.visible = true
	segment_state = SegmentState.FALLING
	var target_root_position: Vector2 = (
		global_position
		+ end_position
		- top_marker.global_position
	)

	if is_zero_approx(fall_duration):
		global_position = target_root_position
		segment_state = SegmentState.SETTLED
		fall_completed.emit()
		return

	fall_tween = create_tween()
	fall_tween.set_trans(Tween.TRANS_LINEAR)
	fall_tween.tween_property(
		self,
		"global_position",
		target_root_position,
		fall_duration
	)
	fall_tween.finished.connect(_on_fall_tween_finished)


# 暂停当前断段的掉落Tween，不改变段状态或目标位置。
func pause_fall_motion() -> void:
	if segment_state == SegmentState.FALLING and fall_tween != null and fall_tween.is_valid():
		fall_tween.pause()


# 从原进度继续当前断段的掉落Tween。
func resume_fall_motion() -> void:
	if segment_state == SegmentState.FALLING and fall_tween != null and fall_tween.is_valid():
		fall_tween.play()


# 返回活动段是否仍在追赶累计的推出目标。
func is_moving() -> bool:
	return (
		segment_state == SegmentState.ACTIVE
		and not is_equal_approx(
			_get_length_pixels(),
			movement_target_length_pixels
		)
	)


# 返回当前段是否正在执行掉落动画。
func is_falling() -> bool:
	return segment_state == SegmentState.FALLING


# 返回当前段是否已经落定。
func is_settled() -> bool:
	return segment_state == SegmentState.SETTLED


# 根据顶部与BottomMarker的实际距离计算当前段长度。
func get_length_cm() -> float:
	if not is_initialized:
		return 0.0

	var length_pixels: float = maxf(
		bottom_marker.global_position.y - top_marker.global_position.y,
		0.0
	)
	return LengthUnits.pixels_to_cm(length_pixels)


# 返回当前段的BottomMarker是否已到达初始化时保存的堵塞阈值。
func has_reached_clog_threshold() -> bool:
	return is_initialized and bottom_marker.global_position.y >= clog_threshold_y


# 返回当前段底端进入管道阈值后的实际深度，仅供Tube视觉预览读取。
func get_clog_penetration_cm() -> float:
	if not is_initialized:
		return 0.0

	var penetration_pixels: float = maxf(
		bottom_marker.global_position.y - clog_threshold_y,
		0.0
	)
	return LengthUnits.pixels_to_cm(penetration_pixels)


# 返回BottomMarker当前表示的非负像素长度。
func _get_length_pixels() -> float:
	return maxf(bottom_marker.position.y - top_marker.position.y, 0.0)


# 同步BottomMarker与占位图片，使图片顶部保持固定。
func _set_length_pixels(length_pixels: float) -> void:
	var safe_length: float = maxf(length_pixels, 0.0)
	bottom_marker.position = Vector2(top_marker.position.x, top_marker.position.y + safe_length)
	visuals.position = top_marker.position

	var visual_scale_y: float = maxf(absf(visuals.scale.y), 0.001)
	var source_length: float = safe_length / visual_scale_y
	body.visible = safe_length > 0.0
	body.position = Vector2(0.0, source_length * 0.5)
	bottom_cap.position = Vector2(0.0, source_length)

	if body.texture != null:
		body.region_rect = Rect2(
			0.0,
			0.0,
			float(body.texture.get_width()),
			maxf(source_length, 1.0)
		)


# 掉落Tween结束后将当前段锁定为SETTLED。
func _on_fall_tween_finished() -> void:
	segment_state = SegmentState.SETTLED
	fall_tween = null
	fall_completed.emit()

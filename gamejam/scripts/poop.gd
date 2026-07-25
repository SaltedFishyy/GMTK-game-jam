class_name Poop
extends Node2D

enum SegmentState {
	ACTIVE,
	FALLING,
	SETTLED,
}

@export_range(0.1, 100.0, 0.1, "suffix:px/cm") var pixels_per_cm: float = 10.0
@export_range(0.0, 3.0, 0.05, "suffix:s") var fall_duration: float = 0.5

@onready var poop_visual: Sprite2D = $Poopholder
@onready var top_marker: Marker2D = $TopMarker
@onready var bottom_marker: Marker2D = $BottomMarker

var clog_threshold_y: float = 0.0
var movement_target_length_pixels: float = 0.0
var segment_state: SegmentState = SegmentState.ACTIVE
var is_initialized: bool = false


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
	segment_state = SegmentState.FALLING
	var target_root_position: Vector2 = (
		global_position
		+ end_position
		- top_marker.global_position
	)

	if is_zero_approx(fall_duration):
		global_position = target_root_position
		segment_state = SegmentState.SETTLED
		return

	var new_fall_tween: Tween = create_tween()
	new_fall_tween.set_trans(Tween.TRANS_LINEAR)
	new_fall_tween.tween_property(
		self,
		"global_position",
		target_root_position,
		fall_duration
	)
	new_fall_tween.finished.connect(_on_fall_tween_finished)


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
	if not is_initialized or is_zero_approx(pixels_per_cm):
		return 0.0

	var length_pixels: float = maxf(
		bottom_marker.global_position.y - top_marker.global_position.y,
		0.0
	)
	return length_pixels / pixels_per_cm


# 返回当前Poop使用的安全像素到厘米换算率。
func get_pixels_per_cm() -> float:
	return maxf(pixels_per_cm, 0.001)


# 根据活动段BottomMarker超过堵塞阈值的距离计算超出长度。
func get_excess_length_cm() -> float:
	if (
		not is_initialized
		or segment_state != SegmentState.ACTIVE
		or is_zero_approx(pixels_per_cm)
	):
		return 0.0

	var excess_pixels: float = maxf(
		bottom_marker.global_position.y - clog_threshold_y,
		0.0
	)
	return excess_pixels / pixels_per_cm


# 返回BottomMarker当前表示的非负像素长度。
func _get_length_pixels() -> float:
	return maxf(bottom_marker.position.y - top_marker.position.y, 0.0)


# 同步BottomMarker与占位图片，使图片顶部保持固定。
func _set_length_pixels(length_pixels: float) -> void:
	var safe_length: float = maxf(length_pixels, 0.0)
	bottom_marker.position = Vector2(top_marker.position.x, top_marker.position.y + safe_length)
	poop_visual.position = Vector2(
		top_marker.position.x,
		top_marker.position.y + safe_length * 0.5
	)
	poop_visual.visible = safe_length > 0.0

	if poop_visual.texture == null:
		return

	var texture_height: float = maxf(float(poop_visual.texture.get_height()), 1.0)
	poop_visual.scale.y = safe_length / texture_height


# 掉落Tween结束后将当前段锁定为SETTLED。
func _on_fall_tween_finished() -> void:
	segment_state = SegmentState.SETTLED

class_name Poop
extends Node2D

@export_range(0.1, 100.0, 0.1, "suffix:px/cm") var pixels_per_cm: float = 10.0

@onready var top_marker: Marker2D = $TopMarker
@onready var bottom_marker: Marker2D = $BottomMarker

var initial_bottom_y: float = 0.0
var clog_threshold_y: float = 0.0
var movement_target_global_position: Vector2
var is_initialized: bool = false


# 将底部 Marker 对齐出生点，并记录长度起点和堵塞阈值。
func initialize(spawn_position: Vector2, clog_threshold_position: Vector2) -> void:
	global_position += spawn_position - bottom_marker.global_position
	initial_bottom_y = bottom_marker.global_position.y
	clog_threshold_y = clog_threshold_position.y
	movement_target_global_position = global_position
	is_initialized = true


# 将一次推出距离沿Y轴向下累加到当前移动目标。
func push_distance(distance_pixels: float) -> void:
	if not is_initialized or distance_pixels <= 0.0:
		return

	movement_target_global_position.y += distance_pixels


# 让整个 Poop 根节点平滑追赶当前累计的移动目标。
func update_movement(delta: float, move_speed: float) -> void:
	if not is_initialized or not is_moving():
		return

	global_position = global_position.move_toward(
		movement_target_global_position,
		maxf(move_speed, 0.0) * delta
	)


# 返回 Poop 是否仍在追赶累计的移动目标。
func is_moving() -> bool:
	return not global_position.is_equal_approx(movement_target_global_position)


# 根据 BottomMarker 从初始位置向下移动的距离计算当前长度。
func get_length_cm() -> float:
	if not is_initialized or is_zero_approx(pixels_per_cm):
		return 0.0

	var moved_pixels: float = maxf(
		bottom_marker.global_position.y - initial_bottom_y,
		0.0
	)
	return moved_pixels / pixels_per_cm


# 根据 TopMarker 超过堵塞阈值的实际距离计算超出长度。
func get_excess_length_cm() -> float:
	if not is_initialized or is_zero_approx(pixels_per_cm):
		return 0.0

	var excess_pixels: float = maxf(
		top_marker.global_position.y - clog_threshold_y,
		0.0
	)
	return excess_pixels / pixels_per_cm

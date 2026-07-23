class_name Poop
extends Node2D

@export_range(0.1, 100.0, 0.1, "suffix:px/cm") var pixels_per_cm: float = 10.0

@onready var top_marker: Marker2D = $TopMarker
@onready var bottom_marker: Marker2D = $BottomMarker

var initial_bottom_y: float = 0.0
var target_global_position: Vector2
var is_initialized: bool = false
var reached_end: bool = false


# 将底部 Marker 对齐出生点，并记录长度起点和根节点终点。
func initialize(spawn_position: Vector2, end_position: Vector2) -> void:
	global_position += spawn_position - bottom_marker.global_position
	initial_bottom_y = bottom_marker.global_position.y
	target_global_position = global_position + end_position - top_marker.global_position
	reached_end = global_position == target_global_position
	is_initialized = true


# 让整个 Poop 根节点以指定速度向终点移动。
func move_forward(delta: float, move_speed: float) -> void:
	if not is_initialized or reached_end:
		return

	global_position = global_position.move_toward(
		target_global_position,
		maxf(move_speed, 0.0) * delta
	)

	if global_position == target_global_position:
		reached_end = true


# 根据 BottomMarker 从初始位置向下移动的距离计算当前长度。
func get_length_cm() -> float:
	if not is_initialized or is_zero_approx(pixels_per_cm):
		return 0.0

	var moved_pixels: float = maxf(
		bottom_marker.global_position.y - initial_bottom_y,
		0.0
	)
	return moved_pixels / pixels_per_cm


# 返回 Poop 是否已经准确到达终点。
func has_reached_end() -> bool:
	return reached_end

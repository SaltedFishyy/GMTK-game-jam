class_name QTEBar
extends Control

signal qte_succeeded
signal qte_failed

@export_range(10.0, 1200.0, 10.0, "suffix:px/s") var pointer_speed: float = 400.0
@export_range(10.0, 500.0, 5.0, "suffix:px") var target_area_width: float = 120.0

@onready var bar_background: ColorRect = $BarBackground
@onready var target_area: ColorRect = $BarBackground/TargetArea
@onready var pointer: ColorRect = $BarBackground/Pointer

var random_number_generator: RandomNumberGenerator = RandomNumberGenerator.new()
var pointer_direction: float = 1.0
var is_active: bool = false


# 初始化随机数生成器，并让未激活的组件保持隐藏。
func _ready() -> void:
	random_number_generator.randomize()
	hide()
	set_process(false)


# 激活一次新的QTE，并随机放置目标区域。
func start_qte() -> void:
	if is_active:
		return

	var available_width: float = bar_background.size.x
	var actual_target_width: float = clampf(
		target_area_width,
		1.0,
		available_width
	)
	var target_x: float = random_number_generator.randf_range(
		0.0,
		available_width - actual_target_width
	)

	target_area.position = Vector2(target_x, 0.0)
	target_area.size = Vector2(actual_target_width, bar_background.size.y)
	pointer.position = Vector2(0.0, 0.0)
	pointer_direction = 1.0
	is_active = true
	show()
	set_process(true)


# 取消当前QTE，不发送成功或失败信号。
func cancel_qte() -> void:
	if not is_active:
		return

	is_active = false
	set_process(false)
	hide()


# 安全设置指针速度，不暴露或操作组件内部节点。
func configure_pointer_speed(speed: float) -> void:
	pointer_speed = maxf(speed, 0.0)


# 让指针在判定条左右边界之间持续往返。
func _process(delta: float) -> void:
	var right_limit: float = maxf(
		bar_background.size.x - pointer.size.x,
		0.0
	)
	var next_x: float = (
		pointer.position.x
		+ pointer_speed * pointer_direction * delta
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


# 根据指针中心是否位于目标区域内完成本次判定。
func _judge_pointer_position() -> void:
	var pointer_center_x: float = pointer.position.x + pointer.size.x * 0.5
	var target_left: float = target_area.position.x
	var target_right: float = target_left + target_area.size.x
	var succeeded: bool = (
		pointer_center_x >= target_left
		and pointer_center_x <= target_right
	)

	is_active = false
	set_process(false)
	hide()

	if succeeded:
		qte_succeeded.emit()
	else:
		qte_failed.emit()

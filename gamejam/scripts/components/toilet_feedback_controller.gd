class_name ToiletFeedbackController
extends Node

var is_configured: bool = false

var left_door: Sprite2D
var warning_label: Label
var butt: Sprite2D
var door_shake_amplitude: float = 0.0
var door_shake_speed: float = 0.1
var butt_shake_amplitude: float = 0.0
var butt_shake_speed: float = 0.1
var left_door_initial_position: Vector2 = Vector2.ZERO
var butt_initial_position: Vector2 = Vector2.ZERO
var left_door_shake_tween: Tween
var butt_shake_tween: Tween


func configure(
	left_door_node: Sprite2D,
	warning_label_node: Label,
	butt_node: Sprite2D,
	door_amplitude: float,
	door_speed: float,
	butt_amplitude: float,
	butt_speed: float
) -> void:
	left_door = left_door_node
	warning_label = warning_label_node
	butt = butt_node
	door_shake_amplitude = door_amplitude
	door_shake_speed = door_speed
	butt_shake_amplitude = butt_amplitude
	butt_shake_speed = butt_speed
	left_door_initial_position = left_door.position
	butt_initial_position = butt.position
	is_configured = true
	stop_all()


func start_qte_warning(text: String) -> void:
	if not is_configured:
		return

	stop_qte_warning()
	warning_label.text = text
	warning_label.show()
	if is_zero_approx(door_shake_amplitude):
		return

	var safe_speed: float = maxf(door_shake_speed, 0.1)
	left_door_shake_tween = _create_horizontal_shake_tween(
		left_door,
		left_door_initial_position.x,
		door_shake_amplitude,
		1.0 / (safe_speed * 2.0),
		1.0 / safe_speed
	)


func stop_qte_warning() -> void:
	if not is_configured:
		return

	if left_door_shake_tween != null and left_door_shake_tween.is_valid():
		left_door_shake_tween.kill()
	left_door_shake_tween = null
	if is_instance_valid(left_door):
		left_door.position = left_door_initial_position
	if is_instance_valid(warning_label):
		warning_label.hide()


func start_butt_charge() -> void:
	if not is_configured:
		return

	stop_butt_charge()
	if is_zero_approx(butt_shake_amplitude):
		return

	var safe_speed: float = maxf(butt_shake_speed, 0.1)
	butt_shake_tween = _create_horizontal_shake_tween(
		butt,
		butt_initial_position.x,
		butt_shake_amplitude,
		1.0 / (safe_speed * 4.0),
		1.0 / (safe_speed * 2.0)
	)


func stop_butt_charge() -> void:
	if not is_configured:
		return

	if butt_shake_tween != null and butt_shake_tween.is_valid():
		butt_shake_tween.kill()
	butt_shake_tween = null
	if is_instance_valid(butt):
		butt.position = butt_initial_position


func stop_all() -> void:
	if not is_configured:
		return

	stop_qte_warning()
	stop_butt_charge()


func _create_horizontal_shake_tween(
	target: Node2D,
	initial_x: float,
	amplitude: float,
	quarter_cycle_duration: float,
	half_cycle_duration: float
) -> Tween:
	var shake_tween: Tween = create_tween()
	shake_tween.set_loops()
	shake_tween.tween_property(
		target,
		"position:x",
		initial_x + amplitude,
		quarter_cycle_duration
	).set_trans(Tween.TRANS_LINEAR)
	shake_tween.tween_property(
		target,
		"position:x",
		initial_x - amplitude,
		half_cycle_duration
	).set_trans(Tween.TRANS_LINEAR)
	shake_tween.tween_property(
		target,
		"position:x",
		initial_x,
		quarter_cycle_duration
	).set_trans(Tween.TRANS_LINEAR)
	return shake_tween

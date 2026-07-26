class_name TubeIndicator
extends Node2D

const IDLE_ANIMATION: StringName = &"idle"
const FLOWING_ANIMATION: StringName = &"flowing"

@export var mini_poop_window_rect: Rect2 = Rect2(-35.0, -95.0, 70.0, 165.0)
@export_range(0.4, 0.55, 0.01) var mini_poop_width_ratio: float = 0.5
@export var mini_poop_position_offset: Vector2 = Vector2.ZERO
@export_range(0.01, 5.0, 0.01) var mini_poop_length_scale: float = 1.0

var is_flowing: bool = false
var is_gameplay_paused: bool = false
var pending_has_poop: bool = false
var pending_penetration_cm: float = 0.0

@onready var tube: AnimatedSprite2D = $Tube
@onready var mini_poop_window: Control = $MiniPoopWindow
@onready var mini_poop_visual: Node2D = $MiniPoopWindow/MiniPoopVisual
@onready var mini_poop_body: Sprite2D = $MiniPoopWindow/MiniPoopVisual/Body
@onready var mini_poop_bottom_cap: Sprite2D = $MiniPoopWindow/MiniPoopVisual/BottomCap
@onready var distance_to_clog_label: Label = $DistanceToClogLabel


func _ready() -> void:
	_configure_mini_poop_window()
	_apply_mini_poop_preview()
	_set_flowing_state(false)


func update_indicator(
	has_poop_in_tube: bool,
	clog_penetration_cm: float,
	current_total_poop_length_cm: float,
	clog_target_length_cm: float
) -> void:
	pending_has_poop = has_poop_in_tube
	pending_penetration_cm = maxf(clog_penetration_cm, 0.0)
	_set_flowing_state(has_poop_in_tube)
	if not is_gameplay_paused:
		_apply_mini_poop_preview()
	distance_to_clog_label.text = (
		"%dFT TO CLOG" % _get_remaining_feet(current_total_poop_length_cm, clog_target_length_cm)
	)


func pause_animation() -> void:
	is_gameplay_paused = true
	if is_flowing and tube.is_playing():
		tube.pause()


func resume_animation() -> void:
	is_gameplay_paused = false
	_apply_mini_poop_preview()
	if is_flowing and not tube.is_playing():
		tube.play(FLOWING_ANIMATION)


func _configure_mini_poop_window() -> void:
	mini_poop_window.position = mini_poop_window_rect.position
	mini_poop_window.size = Vector2(
		maxf(mini_poop_window_rect.size.x, 0.0),
		maxf(mini_poop_window_rect.size.y, 0.0)
	)


func _apply_mini_poop_preview() -> void:
	mini_poop_visual.visible = pending_has_poop
	if not pending_has_poop or mini_poop_body.texture == null or mini_poop_bottom_cap.texture == null:
		mini_poop_body.visible = false
		return

	var safe_width_ratio: float = clampf(mini_poop_width_ratio, 0.4, 0.55)
	var target_width: float = mini_poop_window.size.x * safe_width_ratio
	var source_width: float = float(mini_poop_body.texture.get_width())
	if source_width <= 0.0:
		mini_poop_visual.visible = false
		return

	var visual_scale: float = target_width / source_width
	mini_poop_visual.scale = Vector2(visual_scale, visual_scale)
	mini_poop_visual.position = Vector2(
		mini_poop_window.size.x * 0.5 + mini_poop_position_offset.x,
		mini_poop_position_offset.y
	)

	var cap_display_height: float = (
		float(mini_poop_bottom_cap.texture.get_height()) * visual_scale
	)
	var available_display_height: float = maxf(
		mini_poop_window.size.y - maxf(mini_poop_position_offset.y, 0.0),
		0.0
	)
	var body_display_length: float = minf(
		pending_penetration_cm * mini_poop_length_scale,
		maxf(available_display_height - cap_display_height, 0.0)
	)
	var body_source_length: float = body_display_length / maxf(visual_scale, 0.001)

	mini_poop_body.visible = body_display_length > 0.0
	mini_poop_body.position = Vector2(0.0, body_source_length * 0.5)
	mini_poop_body.region_rect = Rect2(
		0.0,
		0.0,
		source_width,
		maxf(body_source_length, 1.0)
	)
	mini_poop_bottom_cap.position = Vector2(
		0.0,
		body_source_length + float(mini_poop_bottom_cap.texture.get_height()) * 0.5
	)


func _set_flowing_state(should_flow: bool) -> void:
	if should_flow == is_flowing and tube.animation != &"":
		return

	is_flowing = should_flow
	if is_flowing:
		tube.animation = FLOWING_ANIMATION
		if is_gameplay_paused:
			tube.stop()
		else:
			tube.play()
	else:
		tube.stop()
		tube.animation = IDLE_ANIMATION
		tube.frame = 0


func _get_remaining_feet(current_total_poop_length_cm: float, clog_target_length_cm: float) -> int:
	var remaining_cm: float = maxf(clog_target_length_cm - current_total_poop_length_cm, 0.0)
	return maxi(ceili(LengthUnits.cm_to_feet(remaining_cm)), 0)

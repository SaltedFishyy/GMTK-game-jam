class_name TubeIndicator
extends Node2D

const IDLE_ANIMATION: StringName = &"idle"
const FLOWING_ANIMATION: StringName = &"flowing"
const CENTIMETERS_PER_FOOT: float = 30.48

var is_flowing: bool = false
var is_gameplay_paused: bool = false

@onready var tube: AnimatedSprite2D = $Tube
@onready var distance_to_clog_label: Label = $DistanceToClogLabel


func _ready() -> void:
	_set_flowing_state(false)


func update_indicator(
	has_poop_in_tube: bool, current_total_poop_length_cm: float, clog_target_length_cm: float
) -> void:
	_set_flowing_state(has_poop_in_tube)
	distance_to_clog_label.text = (
		"%dFT TO CLOG" % _get_remaining_feet(current_total_poop_length_cm, clog_target_length_cm)
	)


func pause_animation() -> void:
	is_gameplay_paused = true
	if is_flowing and tube.is_playing():
		tube.pause()


func resume_animation() -> void:
	is_gameplay_paused = false
	if is_flowing and not tube.is_playing():
		tube.play(FLOWING_ANIMATION)


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
	return maxi(ceili(remaining_cm / CENTIMETERS_PER_FOOT), 0)

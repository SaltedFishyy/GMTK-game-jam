class_name PoopReserveHUD
extends Control


var maximum_reserve_cm: float = 0.0
var displayed_remaining_cm: float = 0.0
var drain_cm_per_second: float = 0.0
var is_transition_paused: bool = false
var drain_tween: Tween
var fill_clip_base_position: Vector2
var fill_clip_base_size: Vector2

@onready var fill_clip: Control = $FillClip
@onready var poop_fill: TextureRect = $FillClip/PoopFill
@onready var remaining_label: Label = $RemainingLabel


func _ready() -> void:
	fill_clip_base_position = fill_clip.position
	fill_clip_base_size = fill_clip.size
	_apply_displayed_remaining()


func initialize_reserve(
	max_cm: float, remaining_cm: float, visual_drain_cm_per_second: float
) -> void:
	_kill_drain_tween()
	maximum_reserve_cm = maxf(max_cm, 0.0)
	drain_cm_per_second = maxf(visual_drain_cm_per_second, 0.0)
	displayed_remaining_cm = clampf(remaining_cm, 0.0, maximum_reserve_cm)
	is_transition_paused = false
	_apply_displayed_remaining()


func set_remaining_target(remaining_cm: float) -> void:
	var safe_target: float = clampf(remaining_cm, 0.0, maximum_reserve_cm)
	_kill_drain_tween()
	if is_equal_approx(displayed_remaining_cm, safe_target):
		_set_displayed_remaining_cm(safe_target)
		return

	if drain_cm_per_second <= 0.0:
		_set_displayed_remaining_cm(safe_target)
		return

	var transition_duration: float = (
		absf(displayed_remaining_cm - safe_target) / drain_cm_per_second
	)
	drain_tween = create_tween()
	drain_tween.set_trans(Tween.TRANS_LINEAR)
	drain_tween.tween_method(
		_set_displayed_remaining_cm, displayed_remaining_cm, safe_target, transition_duration
	)
	drain_tween.finished.connect(_on_drain_tween_finished)
	if is_transition_paused:
		drain_tween.pause()


func pause_transition() -> void:
	is_transition_paused = true
	if drain_tween != null and drain_tween.is_valid():
		drain_tween.pause()


func resume_transition() -> void:
	is_transition_paused = false
	if drain_tween != null and drain_tween.is_valid():
		drain_tween.play()


func sync_immediately(remaining_cm: float) -> void:
	_kill_drain_tween()
	_set_displayed_remaining_cm(clampf(remaining_cm, 0.0, maximum_reserve_cm))


func _set_displayed_remaining_cm(value: float) -> void:
	displayed_remaining_cm = clampf(value, 0.0, maximum_reserve_cm)
	_apply_displayed_remaining()


func _apply_displayed_remaining() -> void:
	var remaining_ratio: float = 0.0
	if maximum_reserve_cm > 0.0:
		remaining_ratio = clampf(displayed_remaining_cm / maximum_reserve_cm, 0.0, 1.0)

	var fill_height: float = floorf(fill_clip_base_size.y * remaining_ratio)
	var hidden_height: float = fill_clip_base_size.y - fill_height
	fill_clip.position = Vector2(
		fill_clip_base_position.x, fill_clip_base_position.y + hidden_height
	)
	fill_clip.size = Vector2(fill_clip_base_size.x, fill_height)
	poop_fill.position = Vector2(0.0, -hidden_height)
	poop_fill.visible = fill_height > 0.0
	remaining_label.text = "%dFT" % _get_displayed_remaining_feet()


func _get_displayed_remaining_feet() -> int:
	if displayed_remaining_cm <= 0.0:
		return 0
	return maxi(ceili(LengthUnits.cm_to_feet(displayed_remaining_cm)), 1)


func _kill_drain_tween() -> void:
	if drain_tween != null and drain_tween.is_valid():
		drain_tween.kill()
	drain_tween = null


func _on_drain_tween_finished() -> void:
	drain_tween = null

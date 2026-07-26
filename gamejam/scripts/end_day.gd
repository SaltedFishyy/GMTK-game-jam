extends Control

const SHOP_SCENE_PATH: String = "res://scenes/shop.tscn"

var has_requested_shop_transition: bool = false

@onready var day_complete_label: Label = $ResultPanel/DayCompleteLabel
@onready var longest_streak_value: Label = $ResultPanel/LongestStreakValue
@onready var distance_value: Label = $ResultPanel/DistanceValue
@onready var clog_distance_bar: Control = $ResultPanel/ClogDistanceBar
@onready var clog_fill: TextureRect = $ResultPanel/ClogDistanceBar/ClogFill
@onready var clog_fill_right: TextureRect = $ResultPanel/ClogDistanceBar/ClogFillRight
@onready var clog_left: TextureRect = $ResultPanel/ClogDistanceBar/ClogLeft
@onready var payout_value: Label = $ResultPanel/PayoutValue
@onready var wipe_your_button: TextureButton = $WipeYourButton


func _ready() -> void:
	if not GameState.has_last_round_result:
		push_warning("End Day loaded without a completed-round result snapshot.")
	_refresh_result_ui()


func _refresh_result_ui() -> void:
	var completed_day: int = GameState.last_round_day
	if not GameState.has_last_round_result:
		completed_day = GameState.current_day

	day_complete_label.text = "Day %d complete" % clampi(
		completed_day,
		1,
		GameState.MAX_DAYS
	)
	longest_streak_value.text = "%d FT" % _centimeters_to_whole_feet(
		GameState.last_round_longest_streak_cm
	)
	distance_value.text = "%d FT" % _centimeters_to_whole_feet(
		GameState.last_round_distance_remaining_cm
	)
	payout_value.text = str(maxi(GameState.last_round_payout, 0))
	_update_clog_distance_bar(GameState.last_round_total_length_cm)


func _centimeters_to_whole_feet(centimeters: float) -> int:
	return maxi(floori(LengthUnits.cm_to_feet(maxf(centimeters, 0.0))), 0)


func _update_clog_distance_bar(total_length_cm: float) -> void:
	var target_length_cm: float = GameState.get_clog_target_length_cm()
	var progress_ratio: float = clampf(
		total_length_cm / target_length_cm if target_length_cm > 0.0 else 0.0,
		0.0,
		1.0
	)
	var divider_width: float = clog_fill_right.size.x
	var available_width: float = maxf(
		clog_distance_bar.size.x - divider_width,
		0.0
	)
	var completed_width: float = floorf(available_width * progress_ratio)
	var remaining_width: float = maxf(available_width - completed_width, 0.0)

	clog_fill.position = Vector2.ZERO
	clog_fill.size.x = completed_width
	clog_fill_right.position.x = completed_width
	clog_left.position.x = completed_width + divider_width
	clog_left.size.x = remaining_width


func _on_wipe_your_button_pressed() -> void:
	if has_requested_shop_transition:
		return

	has_requested_shop_transition = true
	wipe_your_button.disabled = true
	var scene_change_error: Error = get_tree().change_scene_to_file(
		SHOP_SCENE_PATH
	)
	if scene_change_error != OK:
		has_requested_shop_transition = false
		wipe_your_button.disabled = false
		push_error("Failed to enter Shop: %s" % error_string(scene_change_error))

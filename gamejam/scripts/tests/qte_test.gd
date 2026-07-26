extends Control

const QTEBarScript = preload("res://scripts/components/qte_bar.gd")
const QTERulesScript = preload("res://scripts/qte_rules.gd")
const MIN_WAIT_SECONDS: float = 2.0
const MAX_WAIT_SECONDS: float = 5.0

var random_number_generator: RandomNumberGenerator = RandomNumberGenerator.new()
var selected_sphincter_level: int = 0

@onready var qte_bar: QTEBarScript = $QTEBar
@onready var result_label: Label = $ResultLabel
@onready var next_qte_label: Label = $NextQTELabel
@onready var mode_label: Label = $ModeLabel
@onready var qte_wait_timer: Timer = $QTEWaitTimer


# 初始化测试调度，并安排第一次QTE。
func _ready() -> void:
	random_number_generator.randomize()
	result_label.text = "Waiting for the first QTE..."
	_schedule_next_qte()


# 在2到5秒之间随机安排下一次QTE。
func _schedule_next_qte() -> void:
	var interval_multiplier: float = QTERulesScript.get_sphincter_interval_multiplier(
		selected_sphincter_level
	)
	var wait_seconds: float = random_number_generator.randf_range(
		MIN_WAIT_SECONDS * interval_multiplier,
		MAX_WAIT_SECONDS * interval_multiplier
	)
	next_qte_label.text = "Next QTE in %.1f seconds" % wait_seconds
	qte_wait_timer.start(wait_seconds)


# 等待结束后启动一轮QTE。
func _on_qte_wait_timer_timeout() -> void:
	next_qte_label.text = "QTE ACTIVE - PRESS SPACE"
	result_label.text = "Move the pointer center into the stitched target."
	qte_bar.configure_qte(
		qte_bar.track_speed
		* QTERulesScript.get_sphincter_track_speed_multiplier(selected_sphincter_level),
		QTERulesScript.get_target_center_count(selected_sphincter_level),
		1,
		false
	)
	qte_bar.start_qte()


# 显示成功结果，并在本次结束后安排下一轮。
func _on_qte_bar_qte_succeeded() -> void:
	result_label.text = "SUCCESS"
	_schedule_next_qte()


# 显示失败结果，并在本次结束后安排下一轮。
func _on_qte_bar_qte_failed() -> void:
	result_label.text = "FAILED"
	_schedule_next_qte()


# 选择下一次QTE使用HIGH状态的3个Center格。
func _on_high_button_pressed() -> void:
	_select_sphincter_level(0, "HIGH")


# 选择下一次QTE使用MID状态的5个Center格。
func _on_mid_button_pressed() -> void:
	_select_sphincter_level(1, "MID")


# 选择下一次QTE使用LOW状态的7个Center格。
func _on_low_button_pressed() -> void:
	_select_sphincter_level(2, "LOW")


# 保存测试选择；已经激活的QTE继续使用启动时锁定的配置。
func _select_sphincter_level(level: int, state_name: String) -> void:
	selected_sphincter_level = level
	var center_count: int = QTERulesScript.get_target_center_count(level)
	var speed_multiplier: float = QTERulesScript.get_sphincter_track_speed_multiplier(level)
	var interval_multiplier: float = QTERulesScript.get_sphincter_interval_multiplier(level)
	mode_label.text = "NEXT: %s - %d CELLS - SPEED x%.2f - WAIT x%.2f" % [
		state_name,
		center_count,
		speed_multiplier,
		interval_multiplier,
	]

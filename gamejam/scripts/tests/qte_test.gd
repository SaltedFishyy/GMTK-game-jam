extends Control

const QTEBarScript = preload("res://scripts/components/qte_bar.gd")
const MIN_WAIT_SECONDS: float = 2.0
const MAX_WAIT_SECONDS: float = 5.0

@onready var qte_bar: QTEBarScript = $QTEBar
@onready var result_label: Label = $ResultLabel
@onready var next_qte_label: Label = $NextQTELabel
@onready var qte_wait_timer: Timer = $QTEWaitTimer

var random_number_generator: RandomNumberGenerator = RandomNumberGenerator.new()


# 初始化测试调度，并安排第一次QTE。
func _ready() -> void:
	random_number_generator.randomize()
	result_label.text = "Waiting for the first QTE..."
	_schedule_next_qte()


# 在2到5秒之间随机安排下一次QTE。
func _schedule_next_qte() -> void:
	var wait_seconds: float = random_number_generator.randf_range(
		MIN_WAIT_SECONDS,
		MAX_WAIT_SECONDS
	)
	next_qte_label.text = "Next QTE in %.1f seconds" % wait_seconds
	qte_wait_timer.start(wait_seconds)


# 等待结束后启动一轮QTE。
func _on_qte_wait_timer_timeout() -> void:
	next_qte_label.text = "QTE ACTIVE - PRESS SPACE"
	result_label.text = "Move the pointer into the green area."
	qte_bar.start_qte()


# 显示成功结果，并在本次结束后安排下一轮。
func _on_qte_bar_qte_succeeded() -> void:
	result_label.text = "SUCCESS"
	_schedule_next_qte()


# 显示失败结果，并在本次结束后安排下一轮。
func _on_qte_bar_qte_failed() -> void:
	result_label.text = "FAILED"
	_schedule_next_qte()

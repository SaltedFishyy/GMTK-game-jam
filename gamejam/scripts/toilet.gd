extends Node2D

const POOP_SCENE: PackedScene = preload("res://scenes/poop.tscn")
const PoopScript = preload("res://scripts/poop.gd")
const STARTING_SECONDS: int = 10

@export_range(1.0, 1000.0, 1.0, "suffix:px/s") var poop_move_speed: float = 120.0

@onready var countdown_label: Label = $CountdownLabel
@onready var length_label: Label = $LengthLabel
@onready var money_earned_label: Label = $MoneyEarnedLabel
@onready var total_money_label: Label = $TotalMoneyLabel
@onready var countdown_timer: Timer = $CountdownTimer
@onready var poop_spawn_marker: Marker2D = $PoopSpawnMarker
@onready var poop_end_marker: Marker2D = $PoopEndMarker

var seconds_remaining: int = STARTING_SECONDS
var has_spawned_poop: bool = false
var is_round_active: bool = true
var final_length_cm: float = 0.0
var money_earned: int = 0
var has_settled_money: bool = false
var poop_instance: PoopScript


# 初始化倒计时、长度、金钱显示、Poop 和本轮计时。
func _ready() -> void:
	_update_countdown_label()
	_spawn_poop()
	_update_length_label()
	_update_money_labels()
	countdown_timer.start()


# 检查左键输入，并通过 Poop 接口控制移动和长度显示。
func _process(delta: float) -> void:
	if not is_round_active or not is_instance_valid(poop_instance):
		return

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		poop_instance.move_forward(delta, poop_move_speed)

	_update_length_label()


# 每秒减少剩余时间，并在倒计时结束时保存最终长度。
func _on_countdown_timer_timeout() -> void:
	seconds_remaining = maxi(seconds_remaining - 1, 0)
	_update_countdown_label()

	if seconds_remaining <= 0:
		_end_round()


# 将当前剩余秒数更新到倒计时标签。
func _update_countdown_label() -> void:
	countdown_label.text = str(seconds_remaining)


# 更新当前长度或本轮最终长度的文字。
func _update_length_label(show_final_length: bool = false) -> void:
	if show_final_length:
		length_label.text = "Final Length: %.1f cm" % final_length_cm
	elif is_instance_valid(poop_instance):
		length_label.text = "Length: %.1f cm" % poop_instance.get_length_cm()
	else:
		length_label.text = "Length: 0.0 cm"


# 生成一次 Poop，并交给它完成起点对齐和终点计算。
func _spawn_poop() -> void:
	if has_spawned_poop:
		return

	has_spawned_poop = true
	poop_instance = POOP_SCENE.instantiate() as PoopScript
	add_child(poop_instance)
	poop_instance.initialize(
		poop_spawn_marker.global_position,
		poop_end_marker.global_position
	)


# 更新本轮获得金钱和当前总金钱的文字。
func _update_money_labels() -> void:
	money_earned_label.text = "Money Earned: $%d" % money_earned
	total_money_label.text = "Total Money: $%d" % Economy.total_money


# 使用最终原始长度完成一次且仅一次的金钱结算。
func _settle_round_money() -> void:
	if has_settled_money:
		return

	has_settled_money = true
	money_earned = Economy.add_poop_value(final_length_cm)
	_update_money_labels()


# 保存最终长度、结算金钱并永久结束本轮移动。
func _end_round() -> void:
	if not is_round_active:
		return

	final_length_cm = maxf(poop_instance.get_length_cm(), 0.0)
	is_round_active = false
	countdown_timer.stop()
	_update_length_label(true)
	_settle_round_money()

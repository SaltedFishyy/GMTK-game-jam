extends Node2D

const POOP_SCENE: PackedScene = preload("res://scenes/poop.tscn")
const STARTING_SECONDS: int = 10

@onready var countdown_label: Label = $CountdownLabel
@onready var countdown_timer: Timer = $CountdownTimer
@onready var poop_spawn_marker: Marker2D = $PoopSpawnMarker
@onready var poop_end_marker: Marker2D = $PoopEndMarker

var seconds_remaining: int = STARTING_SECONDS
var has_spawned_poop: bool = false


func _ready() -> void:
	_update_countdown_label()
	countdown_timer.start()


func _on_countdown_timer_timeout() -> void:
	seconds_remaining -= 1
	_update_countdown_label()

	if seconds_remaining <= 0:
		_spawn_poop()


func _update_countdown_label() -> void:
	countdown_label.text = str(seconds_remaining)


func _spawn_poop() -> void:
	if has_spawned_poop:
		return

	has_spawned_poop = true
	countdown_timer.stop()

	var poop: Node2D = POOP_SCENE.instantiate()
	add_child(poop)
	poop.global_position = poop_spawn_marker.global_position

class_name StatsHUD
extends Control

@onready var storage_label: Label = $StatsContainer/StorageGroup/StorageLabel
@onready var storage_bar: ProgressBar = $StatsContainer/StorageGroup/StorageBar
@onready var smoothness_label: Label = $StatsContainer/SmoothnessGroup/SmoothnessLabel
@onready var smoothness_bar: ProgressBar = $StatsContainer/SmoothnessGroup/SmoothnessBar
@onready var integrity_label: Label = $StatsContainer/IntegrityGroup/IntegrityLabel
@onready var integrity_bar: ProgressBar = $StatsContainer/IntegrityGroup/IntegrityBar


# 初次显示PlayerStats，并监听之后的属性变化。
func _ready() -> void:
	PlayerStats.stats_changed.connect(_on_player_stats_changed)
	FoodSystem.food_state_changed.connect(_on_food_state_changed)
	_refresh_effective_stats()


# 属性变化后立即刷新三组文字和进度条。
func _on_player_stats_changed(
	_storage_capacity: int,
	_smoothness: int,
	_integrity: int
) -> void:
	_refresh_effective_stats()


# 食物待生效或当前效果变化后刷新有效属性显示。
func _on_food_state_changed() -> void:
	_refresh_effective_stats()


# 从PlayerStats读取当前有效属性，不在HUD保存副本。
func _refresh_effective_stats() -> void:
	_update_stats(
		PlayerStats.get_effective_storage_capacity(),
		PlayerStats.get_effective_smoothness(),
		PlayerStats.get_effective_integrity()
	)


# 将PlayerStats的当前值同步到占位状态栏。
func _update_stats(
	storage_capacity: int,
	smoothness: int,
	integrity: int
) -> void:
	var safe_storage: int = clampi(storage_capacity, 0, 10)
	var safe_smoothness: int = clampi(smoothness, 0, 10)
	var safe_integrity: int = clampi(integrity, 0, 10)

	storage_bar.value = safe_storage
	smoothness_bar.value = safe_smoothness
	integrity_bar.value = safe_integrity
	storage_label.text = "STORAGE: %d / 10" % safe_storage
	smoothness_label.text = "SMOOTHNESS: %d / 10 - %s" % [
		safe_smoothness,
		_get_smoothness_status(safe_smoothness)
	]
	integrity_label.text = "INTEGRITY: %d / 10 - %s" % [
		safe_integrity,
		_get_integrity_status(safe_integrity)
	]


# 返回顺滑度对应的显示文字，不参与玩法规则。
func _get_smoothness_status(value: int) -> String:
	if value <= 4:
		return "HARD"
	if value <= 7:
		return "NORMAL"
	return "TOO LOOSE"


# 返回完整度对应的显示文字，不参与玩法规则。
func _get_integrity_status(value: int) -> String:
	if value <= 4:
		return "CRUMBLY"
	if value <= 7:
		return "NORMAL"
	return "STEEL GIANT"

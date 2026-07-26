class_name IntroStory
extends Node2D

const STORY_PAPER_PAGE_SCENE: PackedScene = preload("res://scenes/components/story_paper_page.tscn")

@export var story_pages: Array[String] = [

]
@export_range(0.1, 5.0, 0.1, "suffix:s") var paper_move_duration: float = 1.0

var next_page_index: int = 0
var is_transitioning: bool = false
var active_tween: Tween
var story_page_instances: Array[StoryPaperPage] = []

@onready var paper_start_marker: Marker2D = $PaperStartMarker
@onready var paper_center_marker: Marker2D = $PaperCenterMarker
@onready var paper_chain: Node2D = $PaperChain
@onready var animated_toilet_paper: AnimatedSprite2D = $AnimatedToiletPaper
@onready var next_button: TextureButton = $NextButton


# 初始化剧情页，等待玩家第一次点击NEXT。
func _ready() -> void:
	animated_toilet_paper.stop()
	next_button.disabled = false


# 依次吐出新剧情页；最后一页完成后的下一次点击才进入厕所。
func _on_next_button_pressed() -> void:
	if is_transitioning:
		return

	if next_page_index >= story_pages.size():
		_go_to_day_start()
		return

	if _start_page_transition(story_pages[next_page_index]):
		next_page_index += 1


# 创建新纸页，并只移动PaperChain以保持所有页面的局部连接关系。
func _start_page_transition(page_text: String) -> bool:
	var new_page: StoryPaperPage = STORY_PAPER_PAGE_SCENE.instantiate() as StoryPaperPage
	if new_page == null:
		push_error("Failed to instantiate StoryPaperPage.")
		return false

	is_transitioning = true
	next_button.disabled = true
	_stop_active_tween()

	paper_chain.add_child(new_page)
	new_page.global_position = paper_start_marker.global_position
	new_page.set_story_text(page_text)
	animated_toilet_paper.play()

	var chain_move_offset: Vector2 = (
		paper_center_marker.global_position - paper_start_marker.global_position
	)
	active_tween = create_tween()
	active_tween.set_trans(Tween.TRANS_LINEAR)
	active_tween.tween_property(
		paper_chain,
		"global_position",
		paper_chain.global_position + chain_move_offset,
		paper_move_duration
	)
	story_page_instances.append(new_page)
	active_tween.finished.connect(_on_paper_tween_finished)
	return true


# 所有纸页到达目标后暂停厕纸当前帧，并允许玩家继续点击。
func _on_paper_tween_finished() -> void:
	animated_toilet_paper.pause()
	active_tween = null
	is_transitioning = false
	next_button.disabled = false


# 终止仍然有效的旧Tween，避免多个移动同时控制剧情纸链。
func _stop_active_tween() -> void:
	if active_tween != null and active_tween.is_valid():
		active_tween.kill()
	active_tween = null


# 剧情页全部显示后进入每日状态页；失败时恢复NEXT按钮供再次尝试。
func _go_to_day_start() -> void:
	is_transitioning = true
	next_button.disabled = true
	var scene_change_error: Error = get_tree().change_scene_to_file(GameState.DAY_START_SCENE_PATH)
	if scene_change_error == OK:
		return

	push_error(
		(
			"Failed to leave intro story: could not load %s (error %d)."
			% [GameState.DAY_START_SCENE_PATH, scene_change_error]
		)
	)
	is_transitioning = false
	next_button.disabled = false


# 场景离开时清理仍然存在的Tween引用。
func _exit_tree() -> void:
	_stop_active_tween()

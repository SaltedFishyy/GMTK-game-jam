extends Node

const PAPER_BUTTON_PRESS_SFX: AudioStream = preload(
	"res://scenes/resources/music/Interaction/Paper _ button press.wav"
)
const SFX_BUS_NAME: StringName = &"SFX"
const MASTER_BUS_NAME: StringName = &"Master"
const CONNECTION_METADATA: StringName = &"paper_button_sfx_connected"

var paper_button_sfx: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	paper_button_sfx = AudioStreamPlayer.new()
	paper_button_sfx.name = "PaperButtonSFX"
	paper_button_sfx.process_mode = Node.PROCESS_MODE_ALWAYS
	paper_button_sfx.stream = PAPER_BUTTON_PRESS_SFX
	paper_button_sfx.bus = (
		SFX_BUS_NAME
		if AudioServer.get_bus_index(SFX_BUS_NAME) >= 0
		else MASTER_BUS_NAME
	)
	add_child(paper_button_sfx)
	get_tree().node_added.connect(_on_scene_tree_node_added)
	call_deferred("_connect_existing_buttons")


# 新场景和运行时动态创建的按钮都只连接一次，不需要逐帧扫描。
func _on_scene_tree_node_added(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node as BaseButton)


func _connect_existing_buttons() -> void:
	for node: Node in get_tree().root.find_children("*", "BaseButton", true, false):
		_connect_button(node as BaseButton)


func _connect_button(button: BaseButton) -> void:
	if button.has_meta(CONNECTION_METADATA):
		return

	button.set_meta(CONNECTION_METADATA, true)
	button.button_down.connect(_on_button_down.bind(button))


# StartingPage保留自身Flush音效；其他可用按钮在功能回调和切场景前播放纸张音效。
func _on_button_down(button: BaseButton) -> void:
	if button.disabled or _is_starting_page_active():
		return
	paper_button_sfx.play()


func _is_starting_page_active() -> bool:
	var current_scene: Node = get_tree().current_scene
	return (
		current_scene != null
		and current_scene.scene_file_path == GameState.STARTING_PAGE_SCENE_PATH
	)

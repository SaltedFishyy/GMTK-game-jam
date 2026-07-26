class_name StoryPaperPage
extends Node2D

@onready var story_label: Label = $StoryLabel


# 更新当前剧情纸页显示的文字。
func set_story_text(page_text: String) -> void:
	story_label.text = page_text

extends Control

@onready var label_2: Label = $CanvasLayer/Label2/Label2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func setup(t: String = ""):
	label_2.text = t

func _on_exit_button_down() -> void:
	get_tree().change_scene_to_file("res://title.tscn")

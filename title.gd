extends Node2D

var con = load("res://controlsc.tscn")
var opp = load("res://option.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_button_down() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _on_control_button_down() -> void:
	var create = con.instantiate()
	add_child(create)


func _on_option_button_down() -> void:
	var create = opp.instantiate()
	add_child(create)

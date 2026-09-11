extends Node2D

class_name  trees

@onready var ts: Sprite2D = $ts

var z: float
var x: float
var h: float = 0
var side: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup(_z, _x, _h, _side):
	z = _z
	x = _x
	h = _h
	side = _side
	
func read():
	return self
	
func sethue(_hue):
	ts.set_modulate(_hue)

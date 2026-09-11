extends Node2D

class_name dmv

var z: float
var x: float
var h: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup(_z, _x, _h):
	z = _z
	x = _x
	h = _h

func read() -> dmv:
	return self

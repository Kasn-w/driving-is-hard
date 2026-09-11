extends Area2D

@onready var wheel: Sprite2D = $wheel

var mouseIN:bool
var len:float = 0
var temp:Vector2 = Vector2(0,0)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var direction:Vector2 = Vector2(0,0)
	if mouseIN:
		var mousepo:Vector2 = get_global_mouse_position()
		var te = mousepo - wheel.global_position
		len = te.length()
		direction = te.normalized()
	if Input.is_action_just_released("click"):
		mouseIN = false
		temp = Vector2(0,0)
	
	if !(direction == Vector2(0,0)) and mouseIN:
		if (temp == Vector2(0,0)):
			temp = direction
		else:
			var angle:float = temp.angle_to(direction)
			if (abs(wheel.rotation_degrees / 360) < 2.5):
				wheel.rotate(angle*delta * (30 * (len/100)))
			temp = direction
	elif (abs(wheel.rotation) > 0.2):
		var di = -1 if wheel.rotation > 0 else 1
		if (abs(wheel.rotation) > 0.08):
			wheel.rotate(di * 8 * delta)
		else:
			wheel.rotate(di * 1 * delta)
			

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			mouseIN = true

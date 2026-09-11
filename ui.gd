extends Sprite2D

@onready var timer: Timer = $Timer

var stuggle: bool = false
var chane:float = 0.5
var count:int = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if stuggle:
		position = Vector2(position.x, position.y)


func _on_timer_timeout() -> void:
	var time
	if (count < 0):
		count = 0
		time = randf_range(8,10)
	elif (count % 2 == 0):
		position = Vector2(position.x, position.y+5)
		time = 0.3
		count += 1
	elif (count % 2 == 1):
		position = Vector2(position.x, position.y-5)
		time = 0.3
		count += 1
		var t = randf()
		if (t < 0.5):
			count = -1
	
	timer.start(time)
	
func stugglse():
	position = Vector2(position.x, position.y+4)

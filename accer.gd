extends AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func fade(t: float = 1.0):
	var tween = create_tween()
	tween.tween_property(self, "volume_db", -80.0, t)
	tween.finished.connect(reset)

func reset():
	print("hi")
	self.stop()
	self.volume_db = 0.0

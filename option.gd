extends Control

@onready var num: LineEdit = $CanvasLayer/num
@onready var len: LineEdit = $CanvasLayer/len

var n
var l
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	n = DiffiData.number_of_segment
	l = DiffiData.lenght_of_segment
	
	num.text = str(n)
	len.text = str(l)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_exit_button_down() -> void:
	queue_free()

func _on_num_text_submitted(new_text: String) -> void:
	if (new_text.is_valid_int()):
		DiffiData.number_of_segment = int(new_text)
	else:
		num.text = "not number"


func _on_len_text_submitted(new_text: String) -> void:
	if (new_text.is_valid_float()):
		DiffiData.lenght_of_segment = float(new_text)
	else:
		len.text = "not number"

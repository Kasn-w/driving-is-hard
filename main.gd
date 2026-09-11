extends Node2D

@onready var stasu: AudioStreamPlayer = $start
@onready var lowsu: AudioStreamPlayer = $lowergear
@onready var accsu: AudioStreamPlayer = $accer
@onready var carnsu: AudioStreamPlayer = $carnoise
@onready var hittsu: AudioStreamPlayer = $hittree
@onready var colsu: AudioStreamPlayer = $collect
@onready var winsu: AudioStreamPlayer = $win
var _isfade:bool = false
var ttween: Tween
var accsuV: float = -2.0

@export var cam_z: float
@export var focal: float = 350
@export var player_offset: float
@export var cam_height: float = 300
@export var draw_segments:int = 150 
@export var seg_len:float = 200
@export var road_width:float
@export var acc:float
@export var splimit:float

var screen_w: float
var screen_h: float
var horizon_y: float
var speed:float = 0
var spar: Array[Node2D]
var trar: Array[Node2D]
var dmvr: Array[Node2D] = []
var tempspli:int = 0

var timeRUN:bool = false
var rawtime: float = 0

var road:Array[Callable] = []
var roadseglen:float = 200000
var selectroad:Array[Callable] = []

var gear:int = 0
var gearA:Array = [[0,0],[10,15],[8,35],[5,60],[2,100]]

@onready var wheel: Sprite2D = $CanvasLayer/wheelarea/wheel
@onready var tree_h: Timer = $treeH
@onready var colsp: Timer = $colsp
@onready var speedla: Label = $CanvasLayer/speed
@onready var splila: Label = $CanvasLayer/spli
@onready var timela: Label = $CanvasLayer/Panel/Label

var coll = load("res://collect.tscn")
var tre = load("res://trees.tscn")
var windm = load("res://dmv.tscn")
var wins = load("res://win.tscn")

var stun:bool = false
var win: bool = false
var dmvl: bool = false
var dmvgap: float

func _ready() -> void:
	road.append_array([roadtest, road2, road3, road4, 
					road5, road7, road9])
	#print(road[0].call(50))
	
	var vp = get_viewport_rect().size
	screen_w = vp.x
	screen_h = vp.y
	horizon_y = screen_h * 0.42
	
	roadseglen = DiffiData.lenght_of_segment
	var random:int
	var rmax:int = road.size() - 1
	for i in DiffiData.number_of_segment:
		random = randi_range(0,rmax)
		selectroad.append(road[random])
		print(road[random])
	#selectroad.append_array([roadtest, road2])
	
	for i in range(0,floor((draw_segments/2)*4)):
		var thick = floor(i/4)
		var _offset = 350
		var _side = 1 if (i % 2 == 0) else -1
		var _z = randf_range(100+(seg_len*thick),100+(seg_len*(thick+1)))
		var _x = randf_range(road_center_x(_z) + _side * ((road_width/2) + _offset), road_center_x(_z) + _side * ((road_width/2) + _offset + 15000))
		var _h = 0
		
		spawnTree(_z,_x,_h,_side,Color(1.0, 1.0, 1.0, 1.0))
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (timeRUN):
		#print(rawtime)
		rawtime += delta

	gearf()
	cgear()
	if !(stun):
		speed += (acc + (speed * 0.2)) * delta
		accsuV = -5 + (8 * (speed/100))
		#print(accsuV)
		if ((splimit + tempspli) - speed > 1):
			if !(accsu.playing) and (speed < 100):
				_isfade = false
				accsu.play()
			elif (_isfade):
				ttween.kill()
				accsu.stop()
				accsu.volume_db = accsuV
		else:
			if !(_isfade):
				_isfade = true
				fade(accsu,2)
	
	if Input.is_action_pressed("gstop"):
		speed -= 10 * 5 * delta
		if (gear > 1):
			if (speed > (splimit*0.5) - 5):
				speed = clamp(speed, splimit*0.5,splimit + tempspli)
			else:
				speed = clamp(speed, 0,splimit + tempspli)
	elif speed > 0:
		speed -= 3 * delta

	if (speed - (splimit + tempspli) > 10):
		speed -= acc * 10 * delta
	elif (speed > (splimit + tempspli)):
		speed = (splimit + tempspli)
	if (speed < 0):
		speed = 0
	
	var cal = wheel.rotation_degrees
	var spt = (cal/(900*1)) * speed
	var spf = speed - abs(spt)
	
	#print(cal)
	#print(speed, "  :  ",spf, " : ",spt)
	updateText()
	player_offset += spt / 1.5
	#print(spf)
	cam_z += spf / 1.5
	
	player_offset = clamp(player_offset,road_center_x(cam_z) - 15000, road_center_x(cam_z) + 15000)
	
	if (Input.is_action_just_pressed("ui_accept")):
		spawnColl(1000,-250,250,0)
		accsu.play()
		
	if (spar == []):
		var count = 0
		var mul = 0
		var chane = 0.5
		var margin = 100.0
		
		var i = randf()
		var _side = 1 if (randf() > 0.5) else -1
		var _z = randf_range(cam_z+(seg_len*(draw_segments)), cam_z+(seg_len*((draw_segments)+1)))
		var _x = randf_range(
				road_center_x(_z) + _side * margin,
				road_center_x(_z) + _side * ((road_width / 2.0) - margin)
			)
		var _h = 250
		spawnColl(_z,_x,_h,0) #z,x,h,val

		while(i > chane):
			count += 1
			mul = count + (speed / 3)
			_side = 1 if (randf() > 0.5) else -1
			_z = randf_range(cam_z+(seg_len*(draw_segments + mul)), cam_z+(seg_len*((draw_segments + mul + 1 ))))
			_x = randf_range(
				road_center_x(_z) + _side * margin,
				road_center_x(_z) + _side * ((road_width / 2.0) - margin)
			)
			_h = 250
			spawnColl(_z,_x,_h,0) #z,x,h,val
			
			i = randf()
			chane *= 1.2
	
	var max_index = selectroad.size() - 1
	if (win):
		winSc()
		for i in dmvr:
			var te:dmv = i.read()
			if (te.z - cam_z < 30000) and !(dmvl):
				dmvl = true
				dmvgap = te.z - cam_z
				i.setup(cam_z+dmvgap,0,0)
			elif (dmvl):
				i.setup(cam_z+dmvgap,0,0)
	
	queue_redraw()

func gearf():
	var temp:int = gear
	if (Input.is_action_pressed("gear1")):
		gear = 1
	if (Input.is_action_pressed("gear2")):
		gear = 2
	if (Input.is_action_pressed("gear3")):
		gear = 3
	if (Input.is_action_pressed("gear4")):
		gear = 4
	if (speed == 0) and (Input.is_action_pressed("gstop")):
		gear = 0
	
	if (temp == 0) and (temp != gear):
		stasu.play()
	if (gear < temp):
		lowsu.play()
		stun = true
		tempspli = 0
		tree_h.start(1.5)
	elif (gear != temp) and !(timeRUN): 
		timeRUN = true
		
func cgear():
	acc = gearA[gear][0]
	splimit = gearA[gear][1]

#func road_center_x(z: float) -> float:
	#return (z*0.007)**2
	#return 1

func road_center_x(z: float) -> float:
	var max_index = selectroad.size() - 1
	var roadsegcount = clampi(int(floor(z / roadseglen)), 0, max_index)
	var _offset = roadsegcount * roadseglen
	var curroad = selectroad[roadsegcount]
	
	if (z >= (max_index + 1) * roadseglen):
		timeRUN = false
		win = true
	if !(win):
		if (z < (roadseglen * 0.165) + _offset ):
			var resu = S(z, (roadseglen * 0) + _offset, (roadseglen * 0.165) + _offset)
			return (1 - resu) * roadstg(z) + resu * curroad.call(z)
		elif (z < (roadseglen * 0.5) + _offset):
			return  curroad.call(z)
		elif (z < (roadseglen * 0.667) + _offset):
			var resu = S(z, (roadseglen * 0.5) + _offset, (roadseglen * 0.667) + _offset)
			return (1 - resu) *  curroad.call(z) + resu * roadstg(z)
		elif (z < (roadseglen * 1.0) + _offset):
			return roadstg(z)
	else:
		return roadstg(z)
	return roadstg(z)

func S(x, start, end):
	x = (x - start) / (end - start)
	return (3 * (x**2)) - (2 * (x**3))

func project(world_x: float, world_y: float, world_z: float) -> Dictionary:
	var dz = max(world_z - cam_z, 1.0)
	var scalew = (focal - clamp(speed * 1.2,0,250)) / dz
	var cam_x = player_offset
	return {
		"x":screen_w * 0.5 + (world_x - cam_x) * scalew,
		"y":horizon_y + (cam_height - world_y) * scalew,
		"scale": scalew,
		"dz": dz
		}

func _draw() -> void:
	draw_rect(Rect2(0, 0, screen_w, horizon_y), Color(0.323, 0.597, 0.788, 1.0))
	draw_rect(Rect2(0, horizon_y, screen_w, screen_h - horizon_y), Color(0.23, 0.56, 0.23))

	var n = draw_segments
	while n >= 1:
		var z1 = cam_z + n * seg_len
		var z0 = cam_z + (n - 1) * seg_len
		if z0 <= 0 or z1 <= 0: 
			n -= 1
			continue
		
		var seg_index = int(floor(z1 / seg_len))

		var cx1 = road_center_x(z1)
		var cx0 = road_center_x(z0)
		var p1l = project(cx1 - road_width / 2.0, 0.0, z1)
		#print("p1l : ",p1l)
		var p1r = project(cx1 + road_width / 2.0, 0.0, z1)
		var p0l = project(cx0 - road_width / 2.0, 0.0, z0)
		var p0r = project(cx0 + road_width / 2.0, 0.0, z0)
		if p1l.y >= p0l.y or abs(p0l.y - p1l.y) < 0.1:
			n -= 1
			continue
		
		var grass_col = Color(0.23, 0.56, 0.23) if seg_index % 2 == 0 else Color(0.20, 0.52, 0.23)
		draw_rect(Rect2(0, p1l.y, screen_w, max(1.0, p0l.y - p1l.y)), grass_col)

		var road_col = Color(0.34, 0.34, 0.34) if seg_index % 2 == 0 else Color(0.37, 0.37, 0.37)
		draw_colored_polygon(PackedVector2Array([
			Vector2(p1l.x, p1l.y), Vector2(p1r.x, p1r.y),
			Vector2(p0r.x, p0r.y), Vector2(p0l.x, p0l.y)
		]), road_col)

		var rumble_w = 55.0
		var rumble_col = Color(0.90, 0.90, 0.90)
		var lp1 = project(cx1 - road_width / 2.0 - rumble_w, 0.0, z1)
		var lp0 = project(cx0 - road_width / 2.0 - rumble_w, 0.0, z0)
		var rp1 = project(cx1 + road_width / 2.0 + rumble_w, 0.0, z1)
		var rp0 = project(cx0 + road_width / 2.0 + rumble_w, 0.0, z0)
		
		if abs(p1l.x - lp1.x) > 0.1:
			draw_colored_polygon(PackedVector2Array([
				Vector2(lp1.x, lp1.y), Vector2(p1l.x, p1l.y),
				Vector2(p0l.x, p0l.y), Vector2(lp0.x, lp0.y)
			]), rumble_col)
		if abs(rp1.x - p1r.x) > 0.1:
			draw_colored_polygon(PackedVector2Array([
				Vector2(p1r.x, p1r.y), Vector2(rp1.x, rp1.y),
				Vector2(rp0.x, rp0.y), Vector2(p0r.x, p0r.y)
			]), rumble_col)
		
		if seg_index % 8 < 4:
			var dw = 18.0
			var d1l = project(cx1 - dw, 0.0, z1)
			var d1r = project(cx1 + dw, 0.0, z1)
			var d0r = project(cx0 + dw, 0.0, z0)
			var d0l = project(cx0 - dw, 0.0, z0)
			draw_colored_polygon(PackedVector2Array([
				Vector2(d1l.x, d1l.y), Vector2(d1r.x, d1r.y),
				Vector2(d0r.x, d0r.y), Vector2(d0l.x, d0l.y)
			]), Color(0.93, 0.93, 0.93))

		n -= 1
	
	var vi:Array = []
	var un:Array = []
	for i in spar:
		var te:collect = i.read()
		if (te.z - cam_z > 80):
			vi.append(i)
		else:
			if (abs(te.x - player_offset) < 180):
				colhit()
			un.append(i)
	
	for i in trar:
		var te:trees = i.read()
		if (te.z - cam_z > 80):
			vi.append(i)
		else:
			if (abs(te.x - player_offset) < 230):
				treehit()
			un.append(i)
		
	for i in dmvr:
		var te:dmv = i.read()
		if (te.z - cam_z > 80):
			vi.append(i)
		else:
			un.append(i)
		if (te.z - cam_z < 10000):
			i.setup(te.z+(te.z - cam_z),0,0)
	var zindex = 10
	vi.sort_custom(func(a, b): return a.z > b.z)
	for i in un:
		if (i is collect):
			spar.erase(i)
			i.queue_free()
		elif(i is trees):
			var te:trees = i.read()
			var _offset = 350
			var _z = te.z + ((draw_segments / 2) * seg_len)
			var _x = randf_range(road_center_x(_z) + te.side * ((road_width/2) + _offset), road_center_x(_z) + te.side * ((road_width/2) + _offset + 15000))
			var _h = 0
			
			i.setup(_z,_x,_h,te.side)
		elif(i is dmv):
			dmvr.erase(i)
			i.queue_free()
			
	for i in vi:
		if (i is collect):
			var te:collect = i.read()
			var cal:Dictionary = project(te.x ,te.h ,te.z)

			i.position = Vector2(cal.x ,cal.y)
			i.scale = Vector2(cal.scale,cal.scale)
		elif (i is trees):
			var te:trees = i.read()
			var cal:Dictionary = project(te.x ,te.h ,te.z)
			
			i.position = Vector2(cal.x ,cal.y)
			i.scale = Vector2(cal.scale,cal.scale)
		elif  (i is dmv):
			var te:dmv = i.read()
			var cal:Dictionary = project(te.x ,te.h ,te.z)
			
			i.position = Vector2(cal.x ,cal.y)
			i.scale = Vector2(cal.scale,cal.scale)
		i.z_index = zindex
		zindex += 1


func spawnColl(_z:float, _x:float, _h:float, _val:float):
	var create = coll.instantiate()
	create.setup(_z,_x,_h,_val)
	
	add_child(create)
	spar.append(create)

func spawnTree(_z:float, _x:float, _h:float, _side:int, _hue:Color):
	var create = tre.instantiate()
	create.setup(_z,_x,_h,_side)
	
	add_child(create)
	create.sethue(_hue)
	trar.append(create)

func spawnDMV(_z,_x,_h):
	var create = windm.instantiate()
	create.setup(_z,_x,_h)
	
	add_child(create)
	dmvr.append(create)

func treehit():
	hittsu.play()
	stun = true
	tempspli = 0
	speed /= 4
	tree_h.start(1.5)

func colhit():
	tempspli += 5
	colsu.play()
	

func _on_colsp_timeout() -> void:
	colsp.start(1)

func _on_tree_h_timeout() -> void:
	stun = false
	
func updateText():
	speedla.text = str(int(floor(speed)))
	if (int(splila.text) != int(splimit)):
		splila.text = str(int(splimit))
	
	var _time = timestr(rawtime)
	timela.text = _time

func timestr(_time:float):
	var text:String = ""
	var minu: int = int(_time) / 60
	var sec: int = int(_time) % 60
	var hun: int = int(fmod(_time, 1) * 100)
	
	if (minu / 10 == 0):
		text += " "
	text += str(minu)
	text += ":"
	if (sec / 10 == 0):
		text += "0"
	text += str(sec)
	text += ":"
	if (hun / 10 == 0):
		text += "0"
	text += str(hun)
	return text
	

func roadstg(x):
	return 1
	
func roadtest(x):
	return sin(x * 0.0002) * 1300.0
	
func road2(x):
	return 2000*sin((x/5000) + sin(x/5000))

func road3(x):
	return x * cos((x**0.5) * 0.1) * 0.03

func road4(x):
	return 3000 * sin(x/8000) + 500 * sin(x/2500) + 600 * cos(x/8000)

func road5(x):
	return 3000 * tanh((x-15000) / 5000) + 4000 * tanh((x-50000)/10000)

func road6(x):
	return 30000 * (sin(x/2000) / ((x/1000)+1))

func road7(x):
	return 4000*sin(x/3000)*cos(x/7000)

func road8(x):
	return 4000*(sin(x/5000) + (1.0/2) * sin(x/2500) - (1.0/3) * sin(x/1666))

func road9(x):
	return 5000*sin(x/40000)*(1.5 + 0.5*cos(x/12000))

func winSc():
	if (dmvr == []):
		spawnDMV(cam_z+50000,0,0)
		
		winsu.play()
		
		var create = wins.instantiate()
		add_child(create)
		create.setup(timela.text)

func fade(player: AudioStreamPlayer, t: float = 1) -> void:
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80.0, t)
	tween.finished.connect(func():
		player.stop()
		player.volume_db = accsuV
	)
	ttween = tween
	

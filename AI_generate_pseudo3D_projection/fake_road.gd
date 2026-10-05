extends Node2D

# Fake pseudo-3D driving perspective for Godot 2D.
# Attach this script to a Node2D that covers your viewport (no other setup needed).
# Steer with Left/Right, drive with Up/Down (default Godot ui_* input actions).
#
# The whole "3D" world is just numbers (x, height, z) run through project()
# every frame. Nothing here is real 3D geometry - it's all flat 2D drawing.

# ---- tunable world constants ----
@export var road_width: float = 1600.0
@export var seg_len: float = 200.0
@export var cam_height: float = 900.0
@export var draw_segments: int = 150
@export var fov_deg: float = 100.0

@export var max_speed: float = 1500.0
@export var accel_rate: float = 950.0
@export var brake_rate: float = 1700.0
@export var friction: float = 550.0
@export var steer_rate: float = 1250.0

var screen_w: float
var screen_h: float
var horizon_y: float
var focal: float

var cam_z: float = 0.0       # how far you've driven
var player_offset: float = 0.0  # lateral position on the road
var speed: float = 0.0

class Trees:
	var z: float
	var side: float
	var hue: float
	var h: float
	func _init(_z, _side, _hue, _h):
		z = _z
		side = _side
		hue = _hue
		h = _h

class Car:
	var z: float
	var x: float
	var color: Color
	var w: float
	var h: float
	func _init(_z, _x, _color, _w, _h):
		z = _z
		x = _x
		color = _color
		w = _w
		h = _h

var trees: Array = []
var deco_span: float
var cars: Array = []
var car_span: float = 9000.0


func _ready() -> void:
	var vp = get_viewport_rect().size
	screen_w = vp.x
	screen_h = vp.y
	horizon_y = screen_h * 0.42
	var fov_rad = deg_to_rad(fov_deg)
	focal = (screen_h - horizon_y) / tan(fov_rad * 0.5)

	# scatter roadside trees, alternating sides
	var i = 2
	while i < 140:
		var side = -1.0 if i % 2 == 0 else 1.0
		var hue = 95.0 + float((i * 13) % 30)
		var h = 360.0 + float((i * 37) % 170)
		trees.append(Trees.new(i * seg_len, side, hue, h))
		i += 3
	deco_span = 140.0 * seg_len

	# a few fixed obstacle/traffic cars, recycled once passed
	cars.append(Car.new(2600.0, 0, Color(0.91, 0.30, 0.24), 280.0, 200.0))
	cars.append(Car.new(5200.0, 420.0, Color(0.20, 0.60, 0.86), 280.0, 200.0))
	cars.append(Car.new(8000.0, -220.0, Color(0.95, 0.77, 0.06), 280.0, 200.0))


# A gentle winding road - swap this for whatever curve shape you want,
# or drive it from level data instead of a formula.
func road_center_x(z: float) -> float:
	var a = (z*0.007)**2
	var b = sin(z * 0.0009) * 1300.0 + sin(z * 0.00033) * 2000.0
	if (z < 10000):
		return a
	elif (z < 15000):
		return (1-S(z)) * a + S(z) * b
	else:
		return b

func S(x):
	return (3 * (((x-10000)/5000)**2)) - (2 * (((x-10000)/5000)**3))

# The core trick: turn a 3D-ish (x, y-height, z-depth) point into a 2D
# screen position + scale, given the camera's z (forward) and lateral offset.
func project(world_x: float, world_y: float, world_z: float) -> Dictionary:
	var dz = max(world_z - cam_z, 1.0)
	var scale = focal / dz
	var cam_x = player_offset
	return {
		"x": screen_w * 0.5 + (world_x - cam_x) * scale,
		"y": horizon_y + (cam_height - world_y) * scale,
		"scale": scale,
		"dz": dz,
	}


func _process(delta: float) -> void:
	var steer = 0.0
	if Input.is_action_pressed("ui_left"):
		steer -= 1.0
	if Input.is_action_pressed("ui_right"):
		steer += 1.0
	player_offset += steer * steer_rate * delta

	if Input.is_action_pressed("ui_up"):
		speed += accel_rate * delta
	elif Input.is_action_pressed("ui_down"):
		speed -= brake_rate * delta
	elif speed > 0.0:
		speed -= friction * delta

	speed = clamp(speed, -max_speed, max_speed)
	cam_z += speed * delta

	# recycle decorations once they pass behind the camera, so the road
	# feels endless instead of running out of scenery
	for t in trees:
		if t.z < cam_z - 100.0:
			t.z += deco_span
	for c in cars:
		if c.z < cam_z - 100.0:
			c.z += car_span
	
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, screen_w, horizon_y), Color(0.55, 0.73, 0.86))
	draw_rect(Rect2(0, horizon_y, screen_w, screen_h - horizon_y), Color(0.23, 0.56, 0.23))

	var n = draw_segments
	while n >= 1:
		var z1 = cam_z + n * seg_len
		var z0 = cam_z + (n - 1) * seg_len
		var seg_index = int(floor(z1 / seg_len))

		var cx1 = road_center_x(z1)
		var cx0 = road_center_x(z0)
		var p1l = project(cx1 - road_width / 2.0, 0.0, z1)
		var p1r = project(cx1 + road_width / 2.0, 0.0, z1)
		var p0l = project(cx0 - road_width / 2.0, 0.0, z0)
		var p0r = project(cx0 + road_width / 2.0, 0.0, z0)

		var grass_col = Color(0.23, 0.56, 0.23) if seg_index % 2 == 0 else Color(0.20, 0.52, 0.23)
		draw_rect(Rect2(0, p1l.y, screen_w, max(1.0, p0l.y - p1l.y)), grass_col)

		var road_col = Color(0.34, 0.34, 0.34) if seg_index % 2 == 0 else Color(0.37, 0.37, 0.37)
		draw_colored_polygon(PackedVector2Array([
			Vector2(p1l.x, p1l.y), Vector2(p1r.x, p1r.y),
			Vector2(p0r.x, p0r.y), Vector2(p0l.x, p0l.y)
		]), road_col)

		var rumble_w = 55.0
		var rumble_col = Color(0.80, 0.20, 0.20) if seg_index % 4 < 2 else Color(0.90, 0.90, 0.90)
		var lp1 = project(cx1 - road_width / 2.0 - rumble_w, 0.0, z1)
		var lp0 = project(cx0 - road_width / 2.0 - rumble_w, 0.0, z0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(lp1.x, lp1.y), Vector2(p1l.x, p1l.y),
			Vector2(p0l.x, p0l.y), Vector2(lp0.x, lp0.y)
		]), rumble_col)
		var rp1 = project(cx1 + road_width / 2.0 + rumble_w, 0.0, z1)
		var rp0 = project(cx0 + road_width / 2.0 + rumble_w, 0.0, z0)
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

	# gather visible decorations + cars, sort far -> near, draw in that order
	var visible: Array = []
	for t in trees:
		if t.z - cam_z > 80.0:
			visible.append(t)
	for c in cars:
		if c.z - cam_z > 80.0:
			visible.append(c)
	visible.sort_custom(func(a, b): return a.z > b.z)

	for item in visible:
		if item is Trees:
			_draw_tree(item)
		else:
			_draw_car(item)

	# simple hood silhouette for first-person flavor
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, screen_h), Vector2(0, screen_h - 36),
		Vector2(screen_w * 0.22, screen_h - 64), Vector2(screen_w * 0.78, screen_h - 64),
		Vector2(screen_w, screen_h - 36), Vector2(screen_w, screen_h)
	]), Color(0.06, 0.06, 0.07, 0.9))


func _draw_tree(t: Trees) -> void:
	var wx = road_center_x(t.z) + t.side * (road_width / 2.0 + 260.0)
	var base = project(wx, 0.0, t.z)
	if base.dz < 80.0:
		return
	var top = project(wx, t.h, t.z)
	var half_w = 95.0 * base.scale
	var col = Color.from_hsv(t.hue / 360.0, 0.5, 0.3)
	draw_colored_polygon(PackedVector2Array([
		Vector2(base.x - half_w, base.y),
		Vector2(base.x + half_w, base.y),
		Vector2(top.x, top.y)
	]), col)


func _draw_car(c: Car) -> void:
	var wx = road_center_x(c.z) + c.x
	var base = project(wx, 0.0, c.z)
	if base.dz < 80.0:
		return
	var top = project(wx, c.h, c.z)
	var half_w = (c.w / 2.0) * base.scale
	draw_rect(Rect2(base.x - half_w, top.y, half_w * 2.0, base.y - top.y), c.color)
	draw_rect(Rect2(base.x - half_w, top.y, half_w * 2.0, (base.y - top.y) * 0.35), Color(0, 0, 0, 0.25))

extends Node3D
var rng := RandomNumberGenerator.new()

func prop(shape: Mesh,p: Vector3,s: Vector3,c: Color,angle := 0.0) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	if shape is SphereMesh:
		shape.radial_segments = 12
		shape.rings = 6
	n.mesh = shape
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.95
	n.material_override = m
	add_child(n)
	n.position = p
	n.scale = s
	n.rotation.z = angle
	return n

func box(p: Vector3,s: Vector3,c: Color,angle := 0.0) -> MeshInstance3D:
	return prop(BoxMesh.new(),p,s,c,angle)

func oval(p: Vector3,s: Vector3,c: Color) -> MeshInstance3D:
	return prop(SphereMesh.new(),p,s,c)

func sign_at(p: Vector3, words: String) -> void:
	box(p-Vector3(0,0.65,0),Vector3(0.12,1.4,0.15),Color("#654331"))
	box(p,Vector3(2.6,0.55,0.14),Color("#765039"))
	var l := Label3D.new()
	add_child(l)
	l.position = p+Vector3(0,0,0.1)
	l.text = words
	l.font_size = 42
	l.pixel_size = 0.006
	l.modulate = Color("#ffe4b0")

func lantern(p: Vector3) -> void:
	box(p,Vector3(0.28,0.42,0.28),Color("#42382e"))
	var flame := oval(p+Vector3(0,0,0.13),Vector3(0.18,0.28,0.18),Color("#ffbc55"))
	var mat := flame.material_override as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = Color("#ff9a32")
	var light := OmniLight3D.new()
	add_child(light)
	light.position = p+Vector3(0,0,0.4)
	light.light_color = Color("#ffb15b")
	light.light_energy = 1.5
	light.omni_range = 4.0

func beam(a: Vector3,b: Vector3,width: float,tint: Color) -> void:
	var n := box((a+b)*0.5,Vector3(width,a.distance_to(b),width),tint)
	n.quaternion = Quaternion(Vector3.UP,(b-a).normalized())

func window_at(x: float,y: float) -> void:
	var p := Vector3(x,y,-3.05)
	box(p,Vector3(1.7,2.0,0.15),Color("#382f2d"))
	box(p+Vector3(0,0,0.09),Vector3(1.35,1.65,0.05),Color("#91a7a1"))
	for side in [-1.0,1.0]:
		box(p+Vector3(side*0.77,0,0.17),Vector3(0.16,2.0,0.15),Color("#bc925e"))
		box(p+Vector3(0,side*0.91,0.17),Vector3(1.7,0.16,0.15),Color("#bc925e"))
	box(p+Vector3(0,0,0.19),Vector3(0.10,1.7,0.1),Color("#73583c"))
	box(p+Vector3(0,0,0.19),Vector3(1.4,0.10,0.1),Color("#73583c"))

func polish_barn() -> void:
	for x in [24.0,30.0,36.0]:
		window_at(x,3.7)
	for x in [21.0,27.0,33.0,39.0]:
		beam(Vector3(x,5.9,-3.1),Vector3(x,8.1,-0.9),0.25,Color("#503b2d"))
		beam(Vector3(x,8.1,-0.9),Vector3(x,5.9,1.2),0.25,Color("#503b2d"))
	for i in range(32):
		var x := 20.5+float(i)*0.61
		var roof := box(Vector3(x,7.0,-2.1),Vector3(0.59,3.0,0.14),Color("#654a43").lightened(rng.randf_range(0,0.15)))
		roof.rotation.x = -0.78
	for i in range(8):
		var x := 21.5+float(i)*2.4
		beam(Vector3(x,0.2,-2.95),Vector3(x+1.5,1.9,-2.95),0.13,Color("#946c45"))

func grasses() -> void:
	for i in range(36):
		var x := rng.randf_range(-4.5,19.5)
		if (x>5 and x<7) or (x>13 and x<14):
			continue
		var z := rng.randf_range(-2.0,-1.2)
		for j in range(4):
			var h := rng.randf_range(0.16,0.46)
			var leaf := box(Vector3(x+float(j)*0.08,h*0.45,z),Vector3(0.045,h,0.025),Color("#84924c").lightened(rng.randf_range(-0.12,0.2)),rng.randf_range(-0.45,0.45))
			leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _ready() -> void:
	rng.seed = 726
	for i in range(28):
		var x := -15.0+float(i)*4.2
		oval(Vector3(x,1,-24),Vector3(10,7+rng.randf_range(0,4),6),Color("#ad877d"))
		oval(Vector3(x,0,-15),Vector3(7,5+rng.randf_range(0,3),5),Color("#a78b59"))
	for i in range(24):
		var x := -8.0+float(i)*2.0
		var h := rng.randf_range(3.0,5.0)
		var z := rng.randf_range(-10,-5)
		box(Vector3(x,h*0.4,z),Vector3(0.34,h,0.4),Color("#674735"),rng.randf_range(-0.1,0.1))
		for j in range(4):
			oval(Vector3(x+rng.randf_range(-0.8,0.8),h+rng.randf_range(-0.6,0.6),z),Vector3(2.3,2.0,2.1),[Color("#c46c35"),Color("#e1a443"),Color("#a64e32")][(i+j)%3])
	for i in range(14):
		var x := float(i)*1.6-3
		box(Vector3(x,0.65,-2.2),Vector3(0.16,1.3,0.16),Color("#886347"),rng.randf_range(-0.12,0.12))
		if i%4!=2:
			for y in [0.45,0.95]:
				box(Vector3(x+0.8,y,-2.2),Vector3(1.65,0.13,0.13),Color("#a17b53"),rng.randf_range(-0.1,0.1))
	for i in range(24):
		var x := rng.randf_range(-4,19)
		if x>12.5 and x<14.5:
			continue
		var z := rng.randf_range(-1.9,-1.0)
		var p := Vector3(x,0.25,z)
		for j in range(6):
			var a := float(j)*TAU/6
			oval(p+Vector3(cos(a)*0.12,0,sin(a)*0.12),Vector3(0.38,0.46,0.38),Color("#d88127"))
		box(p+Vector3(0,0.25,0),Vector3(0.08,0.15,0.08),Color("#65713b"))
	sign_at(Vector3(1,1.5,-1.8),"THE FORGOTTEN FARM")
	sign_at(Vector3(18,1.5,-1.8),"OLD BARN  >")
	# Barn: open front, individual weathered boards and rafters.
	for i in range(44):
		var x := 21.0+float(i)*0.42
		box(Vector3(x,3,-3.2),Vector3(0.4,6,0.18),Color("#75443b").lightened(rng.randf_range(0,0.13)))
	for x in [21.0,26.0,31.0,36.0,39.0]:
		box(Vector3(x,3,-2.7),Vector3(0.3,6,0.4),Color("#50382c"))
		box(Vector3(x,5.7,-0.8),Vector3(0.3,0.3,4.2),Color("#50382c"))
	for i in range(20):
		box(Vector3(21+float(i)*0.95,6.2,-1.0),Vector3(0.91,0.25,4.5),Color("#59413a"))
	for x in [23.0,29.0,35.0]:
		for j in range(3):
			box(Vector3(x+float(j)*0.65,0.4,-1.8),Vector3(0.62,0.8,0.85),Color("#b59a4f"))
			for k in range(3):
				box(Vector3(x+float(j)*0.65,0.18+float(k)*0.22,-1.35),Vector3(0.64,0.035,0.03),Color("#776437"))
		lantern(Vector3(x,2.3,-2.5))
	sign_at(Vector3(37,1.5,-1.8),"CELLAR  >")
	# Cellar walls and old machinery.
	for i in range(18):
		for j in range(6):
			box(Vector3(40+float(i)*0.85+float(j%2)*0.2,-3+float(j)*0.62,-2.8),Vector3(0.82,0.59,0.3),Color("#4d5355").lightened(rng.randf_range(0,0.12)))
	for x in [42.0,47.0,52.0]:
		box(Vector3(x,-1.7,-2.2),Vector3(1.1,1.5,0.65),Color("#48545a"))
		for j in range(3):
			box(Vector3(x,-2.1+float(j)*0.35,-1.85),Vector3(0.85,0.12,0.12),Color("#a07d45"))
		lantern(Vector3(x,0.2,-2.1))
	sign_at(Vector3(51,-1.7,-1.8),"HUNTERS' ROAD  >")

	polish_barn()
	grasses()

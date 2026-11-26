extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var hud: Label
var turkey: Node3D
var enemies: Array[CharacterBody3D] = []
var game_menu: CanvasLayer
var collected: Array = []
var defeated: Array = []
var double_unlocked := false
var double_ready := true
var joy_jump_old := false
var fork_unlocked := false
var fork_timer := 0.0
var forks: Array[Node3D] = []
var crates: Array[Node3D] = []
var mushrooms: Array[Node3D] = []
var relics: Array[Node3D] = []
var visited_camps: Array = []
var lifts: Array[AnimatableBody3D] = []
var bridges: Array[StaticBody3D] = []
var hazards: Array[Node3D] = []
var shortcut: StaticBody3D
var shortcut_open := false
var woods_checkpoint := false
var dash_unlocked := false
var dash_time := 0.0
var dash_ready := true
var dash_direction := 1.0
var dash_joy_old := false
var shrine: Node3D
var hp := 5
var max_hp := 5
var corn := 0
var pickups: Array[Node3D] = []
var boss: CharacterBody3D
var boss_done := false
var boss_label: Label
var shake := 0.0
var chest: Node3D
var secret_wall: StaticBody3D
var secret_open := false
var reward_taken := false
var gate: StaticBody3D
var effects: Array[Node3D] = []
var fireflies: Array[Node3D] = []
var doors: Array[Dictionary] = []
var door_cooldown := 0.0
var room_id := "1.1"
var discovered_rooms: Array = ["1.1"]
var room_map: Label
var surface_materials: Dictionary = {}
var facing := 1.0
var cooldown := 0.0
var combo := 0
var combo_window := 0.0
var hit_stop := 0.0
var dodge_time := 0.0
var dodge_cooldown := 0.0
var dodge_direction := 1.0
var combat_fx: Array[Node3D] = []
var invulnerable := 0.0
var attack_name := ""
var attack_timer := 0.0
var previous := {}
var spawn := Vector3(0, 2, 0)
var coyote := 0.0
var jump_buffer := 0.0
var checkpoint := false
var cellar_checkpoint := false
var region := ""
var region_timer := 0.0
var region_label: Label
var clock := 0.0
var wings: Array[Node3D] = []

func mesh(parent: Node3D, shape: Mesh, pos: Vector3, color: Color) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = shape
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	m.material_override = mat
	parent.add_child(m)
	m.position = pos
	return m

func ball(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radial_segments = 12
	sphere.rings = 6
	var m := mesh(parent, sphere, pos, color)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.scale = size
	return m

func detail_box(parent: Node3D,p: Vector3,size: Vector3,tint: Color) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return mesh(parent,m,p,tint)

func textured_surface(n: MeshInstance3D,tint: Color,timber: bool) -> void:
	var key := str(tint)+str(timber)
	if not surface_materials.has(key):
		var m := ShaderMaterial.new()
		m.shader = preload("res://terrain_surface.gdshader")
		m.set_shader_parameter("base_color",tint)
		m.set_shader_parameter("wood",1.0 if timber else 0.0)
		surface_materials[key] = m
	n.material_override = surface_materials[key]

func platform(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = pos
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	var timber := size.y<0.7 and pos.y>0.5 and pos.x<74
	var base := Color("#70503a") if timber else Color("#655443")
	var top := Color("#ad8050") if timber else Color("#819b4c")
	textured_surface(detail_box(body,Vector3.ZERO,size,base),base,timber)
	detail_box(body,Vector3(0,size.y/2-0.045,0),Vector3(size.x,0.09,size.z),top)
	var count := maxi(1,int(ceil(size.x/1.8)))
	var step := size.x/float(count)
	for i in range(count):
		var x := -size.x/2+step*(float(i)+0.5)
		var shade := base.lightened(0.08+0.06*sin(float(i)*2.4+pos.x))
		detail_box(body,Vector3(x,0,size.z/2+0.025),Vector3(step-0.035,size.y*0.78,0.08),shade).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if timber:
			for side in [-1.0,1.0]:
				ball(body,Vector3(x+side*step*0.32,0,size.z/2+0.08),Vector3(0.065,0.065,0.04),Color("#343a3c"))
		else:
			var tuft := ball(body,Vector3(x,size.y/2-0.06,size.z/2+0.04),Vector3(step*0.8,0.22,0.16),top.darkened(0.13))
			tuft.rotation.z = sin(float(i)*2.1)*0.12
			if i%3==0:
				ball(body,Vector3(x, -size.y*0.18,size.z/2+0.09),Vector3(step*0.42,size.y*0.30,0.12),Color("#9b8970"))
	if timber:
		for side in [-1.0,1.0]:
			detail_box(body,Vector3(side*(size.x/2-0.12),0,size.z/2+0.09),Vector3(0.15,size.y,0.12),Color("#59402d"))

func actor(pos: Vector3) -> CharacterBody3D:
	var b := CharacterBody3D.new()
	add_child(b)
	b.position = pos
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.2
	col.shape = shape
	b.add_child(col)
	return b

func burst(p: Vector3, tint: Color, amount: int) -> void:
	for i in range(amount):
		var n := ball(self,p,Vector3.ONE*0.12,tint)
		n.set_meta("velocity",Vector3(randf_range(-3,3),randf_range(1,5),randf_range(-1,1)))
		n.set_meta("life",0.45)
		effects.append(n)

func kernel(p: Vector3) -> void:
	var n := ball(self,p,Vector3(0.25,0.36,0.18),Color("#ffcf45"))
	var mat := n.material_override as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = Color("#a76a15")
	n.set_meta("base",p.y)
	n.set_meta("id",str(p.x)+":"+str(p.y))
	pickups.append(n)

func barrier(p: Vector3,size: Vector3,tint: Color) -> StaticBody3D:
	var b := StaticBody3D.new()
	add_child(b)
	b.position = p
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.shape = shape
	b.add_child(col)
	var m := BoxMesh.new()
	m.size = size
	mesh(b,m,Vector3.ZERO,tint)
	return b

func lift(p: Vector3, travel: Vector3, phase: float) -> void:
	var b := AnimatableBody3D.new()
	add_child(b)
	b.position = p
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.6,0.35,3)
	var col := CollisionShape3D.new()
	col.shape = shape
	b.add_child(col)
	var m := BoxMesh.new()
	m.size = shape.size
	mesh(b,m,Vector3.ZERO,Color("#b58b52"))
	for i in range(5):
		detail_box(b,Vector3(-1.04+float(i)*0.52,0.16,0),Vector3(0.49,0.08,3),Color("#cba16a"))
	for side in [-1.0,1.0]:
		detail_box(b,Vector3(side*1.2,0,1.53),Vector3(0.15,0.35,0.1),Color("#68747a"))
	b.set_meta("origin",p)
	b.set_meta("travel",travel)
	b.set_meta("phase",phase)
	lifts.append(b)

func bridge(p: Vector3) -> void:
	var b := barrier(p,Vector3(1.15,0.22,3),Color("#a17b51"))
	b.set_meta("timer",-1.0)
	bridges.append(b)

func spikes(p: Vector3) -> void:
	var n := Node3D.new()
	add_child(n)
	n.position = p
	for i in range(5):
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.22
		cone.height = 0.55
		mesh(n,cone,Vector3(float(i-2)*0.4,0,0),Color("#7d858a"))
	hazards.append(n)

func decorate_world() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7319
	for i in range(72):
		var x := 74.0+float(i)*2.9
		var y := rng.randf_range(0.8,6.5)
		var n := ball(self,Vector3(x,y,-1.8),Vector3.ONE*0.075,Color("#ffe6a1"))
		var mat := n.material_override as StandardMaterial3D
		mat.emission_enabled = true
		mat.emission = Color("#ffd777")
		mat.emission_energy_multiplier = 1.8
		n.set_meta("origin",n.position)
		fireflies.append(n)
	for i in range(45):
		var x := 76.0+float(i)*4.7
		var hill := ball(self,Vector3(x,1.0,-12),Vector3(12,9+rng.randf_range(0,5),4),Color("#60756c") if i%2==0 else Color("#76877a"))
		hill.rotation.z = rng.randf_range(-0.25,0.25)
	for x in [17.0,47.0,78.0,123.0,165.0,207.0,263.0]:
		var y: float = -3.4 if x==47.0 else 0.0
		detail_box(self,Vector3(x,y+0.5,-0.95),Vector3(0.14,1,0.14),Color("#61442e"))
		detail_box(self,Vector3(x,y+1.03,-0.95),Vector3(0.38,0.45,0.38),Color("#4b5355"))
		var glow := ball(self,Vector3(x,y+1.03,-0.72),Vector3(0.25,0.32,0.12),Color("#ffda7b"))
		var mat := glow.material_override as StandardMaterial3D
		mat.emission_enabled = true
		mat.emission = Color("#ffb94f")
		var light := OmniLight3D.new()
		add_child(light)
		light.position = Vector3(x,y+1.1,0.4)
		light.light_color = Color("#ffc477")
		light.light_energy = 0.7
		light.omni_range = 3.5

func doorway(p: Vector3,target: Vector3,room: String,caption: String,requirement: String = "") -> void:
	var n := Node3D.new()
	add_child(n)
	n.position = p
	for side in [-1.0,1.0]:
		detail_box(n,Vector3(side*0.85,0,-0.55),Vector3(0.35,2.5,0.5),Color("#8c795b"))
	detail_box(n,Vector3(0,1.15,-0.55),Vector3(2.05,0.35,0.5),Color("#ad9567"))
	var label := Label3D.new()
	n.add_child(label)
	label.position = Vector3(0,1.65,0)
	label.text = caption
	label.font_size = 36
	label.pixel_size = 0.007
	doors.append({"p":p,"target":target,"room":room,"requirement":requirement})

func build_rooms() -> void:
	# Each room occupies an isolated coordinate range. Doorways connect them.
	for base in [400.0,650.0,900.0,1150.0]:
		platform(Vector3(base+60,-0.5,0),Vector3(120,1,5))
		barrier(Vector3(base-1,10,0),Vector3(1,24,5),Color("#594938"))
		barrier(Vector3(base+121,10,0),Vector3(1,24,5),Color("#594938"))
		for i in range(9):
			var x: float = float(base) + 9.0 + float(i) * 12.0
			var y := 1.6+float(i%3)*1.6
			platform(Vector3(x,y,0),Vector3(5,0.4,3))
			platform(Vector3(x-3,1.2,0),Vector3(2,0.4,3))
			kernel(Vector3(x,y+0.8,0))
			var trunk := CylinderMesh.new()
			trunk.height = 8
			trunk.bottom_radius = 0.7
			trunk.top_radius = 0.25
			mesh(self,trunk,Vector3(x,3,-4),Color("#604a36"))
			ball(self,Vector3(x,7,-4),Vector3(6,4,3),Color("#a47a45") if base<650 else Color("#657d50") if base<900 else Color("#77618b"))
	# A hub, a lower branch, an upgrade sanctuary and a return shortcut.
	doorway(Vector3(284,0.8,0),Vector3(403,1,0),"1.2","E / UP: GRANARY")
	doorway(Vector3(402,0.8,0),Vector3(282,1,0),"1.1","E / UP: FARM")
	doorway(Vector3(518,0.8,0),Vector3(653,1,0),"1.3","E / UP: ROOT CELLARS")
	doorway(Vector3(652,0.8,0),Vector3(516,1,0),"1.2","E / UP: GRANARY")
	doorway(Vector3(460,0.8,0),Vector3(903,1,0),"1.4","E / UP: WIND SANCTUARY")
	doorway(Vector3(902,0.8,0),Vector3(458,1,0),"1.2","E / UP: GRANARY")
	doorway(Vector3(768,0.8,0),Vector3(1153,1,0),"1.5","E / UP: SEALED STOREHOUSE (DASH)","dash")
	doorway(Vector3(1152,0.8,0),Vector3(766,1,0),"1.3","E / UP: ROOT CELLARS")
	doorway(Vector3(1268,0.8,0),Vector3(18,1,0),"1.1","E / UP: FARM SHORTCUT")
	doorway(Vector3(18,0.8,0),Vector3(1266,1,0),"1.5","E / UP: STOREHOUSE (DASH)","dash")
	barrier(Vector3(289,10,0),Vector3(1,24,5),Color("#594938"))
	shrine.position = Vector3(1010,0.9,0)
	for n: Node3D in relics:
		# Reserve these for later realms; no early acquisition.
		n.position = Vector3(-1000,0,0)
		n.hide()

func expansion() -> void:
	for i in range(12):
		var x := 123.0+float(i)*14.0
		platform(Vector3(x,-0.5,0),Vector3(10,1,5))
		platform(Vector3(x+7,-5.5,0),Vector3(14,1,5))
		platform(Vector3(x-3,2,0),Vector3(3,0.4,3))
		platform(Vector3(x+1,4,0),Vector3(3,0.4,3))
		platform(Vector3(x+5,6,0),Vector3(3,0.4,3))
		platform(Vector3(x+7,-2.5,0),Vector3(2.4,0.4,3))
		kernel(Vector3(x+5,6.8,0))
		kernel(Vector3(x+7,-4.2,0))
		var mushroom := Node3D.new()
		add_child(mushroom)
		mushroom.position = Vector3(x+3,0.4,0)
		ball(mushroom,Vector3(0,-0.15,0),Vector3(0.45,0.5,0.45),Color("#e8c8a0"))
		ball(mushroom,Vector3.ZERO,Vector3(1.4,0.55,1.2),Color("#e75a76"))
		for spot in range(5):
			var angle := float(spot)*TAU/5.0
			ball(mushroom,Vector3(cos(angle)*0.43,0.17,sin(angle)*0.36),Vector3(0.19,0.07,0.17),Color("#fff0c8"))
		ball(mushroom,Vector3(0,0.25,0),Vector3(0.35,0.12,0.35),Color("#ffe4ae"))
		mushrooms.append(mushroom)
		var crate := Node3D.new()
		add_child(crate)
		crate.position = Vector3(x-2,0.6,0)
		var box := BoxMesh.new()
		box.size = Vector3(0.85,0.85,0.85)
		mesh(crate,box,Vector3.ZERO,Color("#b67e43"))
		for side in [-1.0,1.0]:
			detail_box(crate,Vector3(side*0.35,0,0.44),Vector3(0.12,0.85,0.07),Color("#70472c"))
			detail_box(crate,Vector3(0,side*0.35,0.44),Vector3(0.85,0.12,0.07),Color("#70472c"))
		var brace := detail_box(crate,Vector3(0,0,0.46),Vector3(0.12,0.91,0.06),Color("#e0aa65"))
		brace.rotation.z = 0.78
		crates.append(crate)
		for j in range(3):
			var tree_x := x+float(j-1)*4
			var trunk := CylinderMesh.new()
			trunk.height = 10
			trunk.bottom_radius = 0.7
			trunk.top_radius = 0.3
			mesh(self,trunk,Vector3(tree_x,3,-5),Color("#554032"))
			ball(self,Vector3(tree_x,8,-5),Vector3(6,5,4),Color("#456b50") if i<4 else Color("#795d91") if i<8 else Color("#a37a48"))
		if i%3==1:
			lift(Vector3(x+7,-4,0),Vector3(0,8,0),float(i))
		if i%3==2:
			spikes(Vector3(x+7,-4.7,0))
	for i in range(2):
		var n := Node3D.new()
		add_child(n)
		n.position = Vector3(124 if i==0 else 180,4.8,0)
		n.set_meta("kind",i)
		ball(n,Vector3.ZERO,Vector3(0.65,0.85,0.4),Color("#f4c9ff") if i==0 else Color("#c9e8ff"))
		var label := Label3D.new()
		n.add_child(label)
		label.position.y = 0.8
		label.text = "SILKEN FEATHERS" if i==0 else "THROWING FORK"
		label.font_size = 40
		label.pixel_size = 0.006
		relics.append(n)
	for x in [123.0,165.0,207.0,263.0]:
		ball(self,Vector3(x,0.3,-0.8),Vector3(1.2,0.35,0.8),Color("#e8cb71"))
	platform(Vector3(282,-0.5,0),Vector3(12,1,5))

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#b7c6b4")
	env.environment.fog_enabled = true
	env.environment.fog_light_color = Color("#a7b8ad")
	env.environment.fog_density = 0.012
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.55
	env.environment.ambient_light_color = Color("#d8e5ff")
	add_child(env)
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.shadow_enabled = false
	sun.light_color = Color("#ffe0ae")
	sun.light_energy = 1.55
	var rim := DirectionalLight3D.new()
	add_child(rim)
	rim.rotation_degrees = Vector3(-25,145,0)
	rim.light_color = Color("#9acbff")
	rim.light_energy = 0.65
	platform(Vector3(0,-0.5,0),Vector3(10,1,5))
	platform(Vector3(10,-0.5,0),Vector3(6,1,5))
	platform(Vector3(7,-4.5,0),Vector3(24,1,5))
	platform(Vector3(6,-2.3,0),Vector3(1.0,0.4,3))
	platform(Vector3(14,-2.4,0),Vector3(1.0,0.4,3))
	platform(Vector3(19,-2.0,0),Vector3(3,0.4,3))

	platform(Vector3(3,1.6,0),Vector3(3,0.4,3))
	platform(Vector3(7,3.3,0),Vector3(3,0.4,3))
	platform(Vector3(11,5.0,0),Vector3(4,0.4,3))
	platform(Vector3(17,5.0,0),Vector3(3,0.4,3))
	platform(Vector3(26,5.0,0),Vector3(4,0.4,3))
	platform(Vector3(30,7.0,0),Vector3(3,0.4,3))
	platform(Vector3(34,9.0,0),Vector3(5,0.4,3))
	platform(Vector3(39,7.2,0),Vector3(4,0.4,3))
	platform(Vector3(43,5.5,0),Vector3(4,0.4,3))
	platform(Vector3(46,4.0,0),Vector3(4,0.4,3))
	platform(Vector3(51,2.0,0),Vector3(4,0.4,3))
	shrine = Node3D.new()
	add_child(shrine)
	shrine.position = Vector3(11,5.8,0)
	for side in [-1.0,1.0]:
		var feather := ball(shrine,Vector3(side*0.3,0,0),Vector3(0.3,0.95,0.2),Color("#a9eaff"))
		feather.rotation.z = side*-0.6
	var hint := Label3D.new()
	shrine.add_child(hint)
	hint.position.y = 0.8
	hint.text = "WINGS OF FREEDOM"
	hint.font_size = 40
	hint.pixel_size = 0.006
	for p in [Vector3(6,-3.3,0),Vector3(10,-3.3,0),Vector3(15,-3.3,0),Vector3(17,5.8,0),Vector3(26,5.8,0),Vector3(34,9.8,0),Vector3(39,8.0,0),Vector3(46,4.7,0)]:
		kernel(p)
	platform(Vector3(17,-0.5,0),Vector3(6,1,5))
	platform(Vector3(29.5,-0.5,0),Vector3(19,1,5))
	platform(Vector3(9,1.3,0),Vector3(3,0.4,3))
	platform(Vector3(13,2.7,0),Vector3(3,0.4,3))
	platform(Vector3(24,1.3,0),Vector3(3,0.4,3))
	platform(Vector3(28,2.7,0),Vector3(3,0.4,3))
	platform(Vector3(32,4.1,0),Vector3(3,0.4,3))
	platform(Vector3(36,2.7,0),Vector3(3,0.4,3))
	platform(Vector3(40,-1.8,0),Vector3(2,0.5,4))
	platform(Vector3(42,-3.1,0),Vector3(2,0.5,4))
	platform(Vector3(49,-4.0,0),Vector3(12,1,5))
	platform(Vector3(55,-2.6,0),Vector3(2,0.5,4))
	platform(Vector3(57,-1.2,0),Vector3(2,0.5,4))
	platform(Vector3(65,-0.5,0),Vector3(16,1,5))
	platform(Vector3(78,-0.5,0),Vector3(10,1,5))
	platform(Vector3(96,-0.5,0),Vector3(12,1,5))
	platform(Vector3(112,-0.5,0),Vector3(12,1,5))
	platform(Vector3(104,-2.0,0),Vector3(1.6,0.35,3))
	platform(Vector3(114,-3.0,0),Vector3(2,0.4,3))
	platform(Vector3(116,-1.4,0),Vector3(2,0.4,3))
	platform(Vector3(87,-5.5,0),Vector3(14,1,5))
	platform(Vector3(104,-5.5,0),Vector3(20,1,5))
	platform(Vector3(79,2.0,0),Vector3(3,0.4,3))
	platform(Vector3(84,4.0,0),Vector3(3,0.4,3))
	platform(Vector3(97,4.0,0),Vector3(4,0.4,3))
	platform(Vector3(102,6.0,0),Vector3(4,0.4,3))
	platform(Vector3(109,4.0,0),Vector3(4,0.4,3))
	platform(Vector3(89,-3.0,0),Vector3(3,0.4,3))
	lift(Vector3(87,4,0),Vector3(7,0,0),0)
	lift(Vector3(104,-4,0),Vector3(0,5.5,0),1.0)
	lift(Vector3(21,1,0),Vector3(0,4,0),0.5)
	for i in range(5):
		bridge(Vector3(84+float(i)*1.2,-0.1,0))
	spikes(Vector3(87,-4.7,0))
	spikes(Vector3(99,-4.7,0))
	spikes(Vector3(103,0.3,0))
	shortcut = barrier(Vector3(110,-3.6,0),Vector3(0.4,3,3),Color("#84613d"))
	for p in [Vector3(79,2.8,0),Vector3(84,4.8,0),Vector3(97,4.8,0),Vector3(102,6.8,0),Vector3(109,4.8,0),Vector3(89,-2.2,0),Vector3(107,-4.2,0)]:
		kernel(p)
	for i in range(20):
		var x := 74.0+float(i)*2.4
		var trunk := CylinderMesh.new()
		trunk.height = 7
		trunk.top_radius = 0.18
		trunk.bottom_radius = 0.45
		mesh(self,trunk,Vector3(x,2,-4),Color("#514438"))
		for j in range(3):
			ball(self,Vector3(x+float(j-1)*0.8,5+float(j%2),-4),Vector3(3.8,3.4,3.2),Color("#536e45") if i%2==0 else Color("#7e8745"))
	platform(Vector3(34,5.5,0),Vector3(5,0.4,3))
	secret_wall = barrier(Vector3(34.8,6.7,0),Vector3(0.4,2.1,3),Color("#89603d"))
	chest = Node3D.new()
	add_child(chest)
	chest.position = Vector3(35,6.0,0)
	var chest_box := BoxMesh.new()
	chest_box.size = Vector3(0.7,0.5,0.55)
	mesh(chest,chest_box,Vector3.ZERO,Color("#80502c"))
	for side in [-1.0,1.0]:
		detail_box(chest,Vector3(side*0.23,0,0.29),Vector3(0.09,0.5,0.05),Color("#e4b75a"))
	detail_box(chest,Vector3(0,0.24,0),Vector3(0.76,0.12,0.6),Color("#b98640"))
	detail_box(chest,Vector3(0,0.04,0.31),Vector3(0.17,0.19,0.06),Color("#eac76d"))
	ball(chest,Vector3(0,0.04,0.35),Vector3(0.045,0.07,0.03),Color("#3b3028"))
	gate = barrier(Vector3(72,8,0),Vector3(0.4,16,4),Color("#56636b"))
	for p in [Vector3(3,0.8,0),Vector3(9,2,0),Vector3(13,3.4,0),Vector3(24,2,0),Vector3(28,3.4,0),Vector3(32,4.8,0),Vector3(44,-2.8,0),Vector3(49,-2.8,0),Vector3(56,-1.5,0)]:
		kernel(p)
	add_child(preload("res://farmstead.gd").new())
	ball(self,Vector3(17,0.3,-0.8),Vector3(1.2,0.35,0.8),Color("#e8cb71"))
	ball(self,Vector3(47,-3.2,-0.8),Vector3(1.2,0.35,0.8),Color("#e8cb71"))
	expansion()
	build_rooms()
	decorate_world()
	add_child(preload("res://world_art.gd").new())
	player = actor(spawn)
	turkey = preload("res://timmy_model.gd").new()
	player.add_child(turkey)
	for x in [5.0, 16.0, 25.0, 34.0, 46.0, 51.0, 65.0, 9.0, 14.0, 27.0, 37.0, 45.0, 78.0, 96.0, 113.0, 121.0, 137.0, 151.0, 163.0, 177.0, 191.0, 205.0, 219.0, 233.0, 247.0, 261.0, 279.0]:
		var e := actor(Vector3(x,-3.2 if x==9.0 or x==14.0 else -2.8 if x>43 and x<54 else 1.0,0))
		var is_boss: bool = x == 65.0
		var kind := 1 if is_boss else enemies.size()%3
		var model = preload("res://enemy_model.gd").new()
		model.kind = kind
		model.champion = is_boss
		e.add_child(model)
		e.set_meta("model",model)
		e.set_meta("kind",kind)
		e.set_meta("hp",14 if is_boss else [2,3,5][kind])
		e.set_meta("boss",is_boss)
		if is_boss:
			boss = e
			model.scale = Vector3.ONE*1.8
			var col := e.get_child(0) as CollisionShape3D
			var capsule := col.shape as CapsuleShape3D
			capsule.radius = 0.65
			capsule.height = 1.8
		e.set_meta("state","patrol")
		e.set_meta("timer",0.0)
		e.set_meta("dir",1.0)
		e.set_meta("stun",0.0)
		var label := Label3D.new()
		label.position = Vector3(0,1.6 if is_boss else 1.0,0)
		label.font_size = 38
		label.pixel_size = 0.005
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		e.add_child(label)
		e.set_meta("label",label)
		e.set_meta("home",x)
		enemies.append(e)
	camera = Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.5
	camera.position = Vector3(2,3,15)
	camera.current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	room_map = Label.new()
	layer.add_child(room_map)
	room_map.position = Vector2(20,200)
	room_map.add_theme_font_size_override("font_size",18)
	hud = Label.new()
	layer.add_child(hud)
	hud.position = Vector2(20,20)
	hud.add_theme_font_size_override("font_size",22)
	region_label = Label.new()
	layer.add_child(region_label)
	region_label.position = Vector2(20,115)
	region_label.add_theme_font_size_override("font_size",30)
	region_label.modulate = Color("#ffe4b0")
	boss_label = Label.new()
	layer.add_child(boss_label)
	boss_label.position = Vector2(20,155)
	boss_label.add_theme_font_size_override("font_size",24)
	boss_label.modulate = Color("#ffb05b")
	game_menu = preload("res://game_menu.gd").new()
	game_menu.set("game",self)
	add_child(game_menu)
	if get_tree().has_meta("skip_title"):
		get_tree().remove_meta("skip_title")
		game_menu.call("resume")
		save_progress()

func save_progress() -> void:
	var file := FileAccess.open("user://turkey_time.save",FileAccess.WRITE)
	if file==null:
		return
	file.store_var({"spawn":spawn,"corn":corn,"max_hp":max_hp,"checkpoint":checkpoint,"cellar":cellar_checkpoint,"boss":boss_done,"secret":secret_open,"reward":reward_taken,"collected":collected,"defeated":defeated,"dash":dash_unlocked,"shortcut":shortcut_open,"woods":woods_checkpoint,"double":double_unlocked,"fork":fork_unlocked,"camps":visited_camps,"room":room_id,"rooms":discovered_rooms})

func load_progress() -> void:
	var file := FileAccess.open("user://turkey_time.save",FileAccess.READ)
	if file==null:
		return
	var data = file.get_var()
	if not data is Dictionary:
		return
	spawn = data.get("spawn",Vector3(0,2,0))
	corn = int(data.get("corn",0))
	dash_unlocked = bool(data.get("dash",false))
	double_unlocked = bool(data.get("double",false))
	fork_unlocked = bool(data.get("fork",false))
	visited_camps = data.get("camps",[])
	room_id = data.get("room","1.1")
	discovered_rooms = data.get("rooms",["1.1"])
	for n: Node3D in relics:
		if (int(n.get_meta("kind"))==0 and double_unlocked) or (int(n.get_meta("kind"))==1 and fork_unlocked):
			n.hide()
	shortcut_open = bool(data.get("shortcut",false))
	woods_checkpoint = bool(data.get("woods",false))
	if shortcut_open and is_instance_valid(shortcut):
		shortcut.queue_free()
	if dash_unlocked:
		shrine.hide()
	max_hp = int(data.get("max_hp",5))
	hp = max_hp
	checkpoint = bool(data.get("checkpoint",false))
	cellar_checkpoint = bool(data.get("cellar",false))
	boss_done = bool(data.get("boss",false))
	secret_open = bool(data.get("secret",false))
	reward_taken = bool(data.get("reward",false))
	collected = data.get("collected",[])
	defeated = data.get("defeated",[])
	for n: Node3D in pickups.duplicate():
		if collected.has(n.get_meta("id")) or collected.has(str(n.position.x)):
			pickups.erase(n)
			n.queue_free()
	for e: CharacterBody3D in enemies.duplicate():
		if defeated.has(e.get_meta("home")):
			enemies.erase(e)
			e.queue_free()
	if boss_done and is_instance_valid(gate):
		gate.queue_free()
	if secret_open and is_instance_valid(secret_wall):
		secret_wall.queue_free()
	if reward_taken and is_instance_valid(chest):
		chest.queue_free()
	player.position = spawn
	player.velocity = Vector3.ZERO


func pressed(key: int) -> bool:
	var now := Input.is_physical_key_pressed(key)
	var old: bool = previous.get(key,false)
	previous[key] = now
	return now and not old

func slash_arc(tint: Color,reach: float) -> void:
	var n := Node3D.new()
	add_child(n)
	n.position = player.position+Vector3(facing*0.35,0,0.65)
	var shape := TorusMesh.new()
	shape.inner_radius = reach*0.65
	shape.outer_radius = reach*0.75
	shape.rings = 24
	shape.ring_segments = 8
	var m := mesh(n,shape,Vector3.ZERO,tint)
	m.rotation.x = PI/2
	m.scale = Vector3(1,1,0.55)
	var mat := m.material_override as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = tint
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	n.set_meta("life",0.14)
	combat_fx.append(n)

func attack(kind: String, reach: float, damage: int, push: float) -> void:
	if cooldown > 0:
		return
	if kind=="Peck":
		combo = combo%3+1 if combo_window>0 else 1
		combo_window = 0.55
		if combo==3:
			damage += 2
			reach += 0.5
			push += 5
		cooldown = 0.12 if combo<3 else 0.24
	else:
		cooldown = 0.24
		combo = 0
		combo_window = 0
	slash_arc(Color("#ffd28a") if kind!="Flap" else Color("#a7e7ff"),reach)
	if kind!="Flap":
		player.velocity.x += facing*3.5
	attack_name = kind
	game_menu.call("sound",kind)
	attack_timer = 0.18
	var tint := Color("#b5eaff") if kind=="Flap" else Color("#ffe3a2")
	burst(player.position+Vector3(facing*reach*0.55,0.15,0.4),tint,10 if kind=="Flap" else 5)
	if not secret_open and kind=="Punch" and player.position.distance_to(Vector3(34.8,6.7,0))<1.8:
		secret_open = true
		secret_wall.queue_free()
		burst(Vector3(34.8,6.7,0),Color("#b88b56"),18)
	for n: Node3D in crates.duplicate():
		if n.position.distance_to(player.position)<reach+0.5 and kind!="Flap":
			burst(n.position,Color("#c58c50"),14)
			corn += 2
			crates.erase(n)
			n.queue_free()
	for e: CharacterBody3D in enemies.duplicate():
		var delta: Vector3 = e.position - player.position
		if absf(delta.y) < 1.4 and absf(delta.x) <= reach+(0.4 if bool(e.get_meta("boss")) else 0.0) and delta.x*facing >= -0.15:
			e.set_meta("hp",int(e.get_meta("hp"))-damage)
			burst(e.position+Vector3(0,0,0.5),Color("#ffb15b"),8)
			shake = 0.19 if damage>=2 else 0.09
			hit_stop = 0.045 if damage>=2 else 0.025
			e.velocity.x = facing*push*(0.25 if bool(e.get_meta("boss")) else 1.0)
			if not bool(e.get_meta("boss")):
				e.set_meta("stun",0.22)
				e.set_meta("state","recover")
				e.set_meta("timer",0.35)
			if int(e.get_meta("hp")) <= 0:
				if bool(e.get_meta("boss")):
					boss_done = true
					gate.queue_free()
					burst(e.position,Color("#ffcc55"),30)
				corn += 5 if bool(e.get_meta("boss")) else 2
				defeated.append(e.get_meta("home"))
				enemies.erase(e)
				e.queue_free()
				if boss_done:
					save_progress()

func _physics_process(dt: float) -> void:
	combo_window = maxf(0,combo_window-dt)
	dodge_cooldown = maxf(0,dodge_cooldown-dt)
	for n: Node3D in combat_fx.duplicate():
		var life: float = float(n.get_meta("life"))-dt
		if life<=0:
			combat_fx.erase(n)
			n.queue_free()
		else:
			n.set_meta("life",life)
			n.scale += Vector3.ONE*dt*2
	cooldown = maxf(0,cooldown-dt)
	invulnerable = maxf(0,invulnerable-dt)
	attack_timer = maxf(0,attack_timer-dt)
	clock += dt
	for n: Node3D in fireflies:
		if absf(n.position.x-player.position.x)>25:
			continue
		var origin: Vector3 = n.get_meta("origin")
		n.position = origin+Vector3(sin(clock*0.8+origin.x)*0.45,cos(clock*1.2+origin.x)*0.35,0)
		n.scale = Vector3.ONE*(0.06+0.025*sin(clock*2+origin.x))
	for b: AnimatableBody3D in lifts:
		var origin: Vector3 = b.get_meta("origin")
		var travel: Vector3 = b.get_meta("travel")
		b.position = origin+travel*(0.5+0.5*sin(clock*0.8+float(b.get_meta("phase"))))
	for b: StaticBody3D in bridges:
		var timer: float = b.get_meta("timer")
		if timer == -1.0 and absf(player.position.x-b.position.x)<0.65 and absf(player.position.y-b.position.y-0.7)<0.3:
			timer = 0.45
		if timer>=0:
			timer -= dt
			if timer<=0:
				b.hide()
				b.collision_layer = 0
				timer = -2.0
				get_tree().create_timer(3.0,false).timeout.connect(func():
					if is_instance_valid(b):
						b.show()
						b.collision_layer = 1
						b.set_meta("timer",-1.0))
		b.set_meta("timer",timer)
	for n: Node3D in hazards:
		if absf(player.position.x-n.position.x)<1.1 and absf(player.position.y-n.position.y)<0.85 and invulnerable<=0:
			hp -= 1
			invulnerable = 1.2
			player.velocity.y = 9
			game_menu.call("sound","hurt")
	if boss_done and not woods_checkpoint and absf(player.position.x-78)<1.0 and player.position.y<2:
		woods_checkpoint = true
		spawn = Vector3(78,1.5,0)
		hp = max_hp
		save_progress()
	if not shortcut_open and player.position.x>110.6 and player.position.y< -2:
		shortcut_open = true
		shortcut.queue_free()
		save_progress()
	shake = maxf(0,shake-dt)
	for n: Node3D in effects.duplicate():
		var life: float = float(n.get_meta("life"))-dt
		if life<=0:
			effects.erase(n)
			n.queue_free()
		else:
			var v: Vector3 = n.get_meta("velocity")
			n.position += v*dt
			v.y -= 12*dt
			n.set_meta("velocity",v)
			n.set_meta("life",life)
			n.scale = Vector3.ONE*0.12*(life/0.45)
	for n: Node3D in pickups.duplicate():
		if absf(n.position.x-player.position.x)>25:
			continue
		n.rotation.y += dt*2.5
		n.position.y = float(n.get_meta("base"))+sin(clock*3+n.position.x)*0.1
		if n.position.distance_to(player.position)<0.7:
			corn += 1
			collected.append(n.get_meta("id"))
			game_menu.call("sound","coin")
			burst(n.position,Color("#ffdb65"),5)
			pickups.erase(n)
			n.queue_free()
	if secret_open and not reward_taken and player.position.distance_to(chest.position)<1.1:
		reward_taken = true
		max_hp += 1
		hp = max_hp
		burst(chest.position,Color("#ffdf77"),20)
		chest.queue_free()
		save_progress()
	var axis := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	if absf(axis)<0.1:
		axis = Input.get_joy_axis(0,JOY_AXIS_LEFT_X)
		if absf(axis)<0.2:
			axis = 0
	player.velocity.x = move_toward(player.velocity.x,axis*10.5,85*dt)
	if axis != 0:
		facing = signf(axis)
	turkey.rotation.y = 0 if facing > 0 else PI
	var joy_jump := Input.is_joy_button_pressed(0,JOY_BUTTON_A)
	var jump := pressed(KEY_SPACE) or (joy_jump and not joy_jump_old)
	joy_jump_old = joy_jump
	if player.is_on_floor():
		double_ready = true
	if jump and double_unlocked and double_ready and not player.is_on_floor() and coyote<=0:
		double_ready = false
		player.velocity.y = 12.5
		burst(player.position,Color("#f4c9ff"),12)
		jump = false
	if jump:
		jump_buffer = 0.13
	else:
		jump_buffer = maxf(0,jump_buffer-dt)
	if player.is_on_floor():
		coyote = 0.12
	else:
		coyote = maxf(0,coyote-dt)
		player.velocity.y -= 20*dt
	if jump_buffer>0 and coyote>0:
		player.velocity.y = 11.5
		coyote = 0
		jump_buffer = 0
	if player.velocity.y>5 and not Input.is_physical_key_pressed(KEY_SPACE) and not Input.is_joy_button_pressed(0,JOY_BUTTON_A):
		player.velocity.y = move_toward(player.velocity.y,5,25*dt)
	if not dash_unlocked and player.position.distance_to(shrine.position)<1.1:
		dash_unlocked = true
		shrine.hide()
		burst(player.position,Color("#a9eaff"),25)
		game_menu.call("sound","checkpoint")
		save_progress()
		region_label.text = "WINGS OF FREEDOM UNLOCKED"
	var joy_dash := Input.is_joy_button_pressed(0,JOY_BUTTON_RIGHT_SHOULDER)
	var dash_pressed := pressed(KEY_SHIFT) or (joy_dash and not dash_joy_old)
	dash_joy_old = joy_dash
	if player.is_on_floor() and dash_time<=0:
		dash_ready = true
	if dash_unlocked and dash_ready and dash_pressed:
		dash_ready = false
		dash_time = 0.22
		dash_direction = facing
		invulnerable = maxf(invulnerable,0.25)
		burst(player.position,Color("#a9eaff"),12)
	if dash_time>0:
		dash_time = maxf(0,dash_time-dt)
		player.velocity = Vector3(dash_direction*28,0,0)
	if (pressed(KEY_C) or Input.is_joy_button_pressed(0,JOY_BUTTON_LEFT_STICK)) and dodge_cooldown<=0 and player.is_on_floor():
		dodge_time = 0.18
		dodge_cooldown = 0.7
		dodge_direction = facing
		invulnerable = maxf(invulnerable,0.24)
		burst(player.position,Color("#cbbda5"),9)
	if dodge_time>0:
		dodge_time = maxf(0,dodge_time-dt)
		player.velocity.x = dodge_direction*18
	player.move_and_slide()
	player.position.z = 0
	for n: Node3D in mushrooms:
		if player.velocity.y<=0 and absf(player.position.x-n.position.x)<0.7 and absf(player.position.y-n.position.y)<0.8:
			player.velocity.y = 17
			burst(n.position,Color("#f4c9ff"),8)
	for n: Node3D in relics:
		if n.visible and player.position.distance_to(n.position)<1.2:
			if int(n.get_meta("kind"))==0:
				double_unlocked = true
			else:
				fork_unlocked = true
			n.hide()
			burst(n.position,Color("#f4c9ff"),25)
			save_progress()
	for x in [123.0,165.0,207.0,263.0]:
		if not visited_camps.has(x) and absf(player.position.x-x)<1.2 and absf(player.position.y)<2:
			visited_camps.append(x)
			spawn = Vector3(x,1.5,0)
			hp = max_hp
			save_progress()
	fork_timer = maxf(0,fork_timer-dt)
	if fork_unlocked and fork_timer<=0 and (pressed(KEY_F) or Input.is_joy_button_pressed(0,JOY_BUTTON_LEFT_SHOULDER)):
		fork_timer = 0.35
		var n := Node3D.new()
		add_child(n)
		n.position = player.position+Vector3(facing*0.6,0.1,0)
		var handle := BoxMesh.new()
		handle.size = Vector3(0.65,0.08,0.08)
		mesh(n,handle,Vector3.ZERO,Color("#dce4ed"))
		for i in range(3):
			var tine := BoxMesh.new()
			tine.size = Vector3(0.25,0.035,0.035)
			mesh(n,tine,Vector3(facing*0.4,float(i-1)*0.09,0),Color("#dce4ed"))
		n.set_meta("velocity",facing*22)
		n.set_meta("life",0.55)
		forks.append(n)
	for n: Node3D in forks.duplicate():
		n.position.x += float(n.get_meta("velocity"))*dt
		var life: float = float(n.get_meta("life"))-dt
		for e: CharacterBody3D in enemies.duplicate():
			if absf(e.position.x-player.position.x)>32:
				continue
			if e.position.distance_to(n.position)<0.8:
				e.set_meta("hp",int(e.get_meta("hp"))-1)
				e.set_meta("stun",0.2)
				burst(e.position,Color("#dce4ed"),8)
				if int(e.get_meta("hp"))<=0:
					if bool(e.get_meta("boss")):
						boss_done = true
						if is_instance_valid(gate):
							gate.queue_free()
					defeated.append(e.get_meta("home"))
					enemies.erase(e)
					e.queue_free()
					corn += 2
				life = 0
				break
		n.set_meta("life",life)
		if life<=0:
			forks.erase(n)
			n.queue_free()
	if pressed(KEY_J) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_joy_button_pressed(0,JOY_BUTTON_X):
		attack("Peck",1.3,1,3)
	if pressed(KEY_K) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_joy_button_pressed(0,JOY_BUTTON_Y):
		attack("Punch",1.6,2,7)
	if pressed(KEY_L) or Input.is_joy_button_pressed(0,JOY_BUTTON_B):
		attack("Flap",3.5,0,12)
	turkey.scale = Vector3(1.15,0.9,1) if attack_timer > 0 else Vector3.ONE
	turkey.call("animate",dt,player.velocity.x,player.is_on_floor(),attack_name,attack_timer)
	if not checkpoint and absf(player.position.x-17)<1.2 and player.position.y<2:
		checkpoint = true
		spawn = Vector3(17,2,0)
		hp = max_hp
		game_menu.call("sound","checkpoint")
		save_progress()
	if not cellar_checkpoint and absf(player.position.x-47)<1.2 and player.position.y<0:
		cellar_checkpoint = true
		spawn = Vector3(47,-2.5,0)
		hp = max_hp
		game_menu.call("sound","checkpoint")
		save_progress()
	var next_region := "THE GRANARY" if room_id=="1.2" else "ROOT CELLARS" if room_id=="1.3" else "WIND SANCTUARY" if room_id=="1.4" else "SEALED STOREHOUSE" if room_id=="1.5" else "THE OLD FARMYARD" if player.position.x<21 else "THE DERELICT BARN" if player.position.x<39 else "THE FORGOTTEN CELLAR" if player.position.x<58 else "THE IRON ROOSTER" if not boss_done else "HUNTERS' ROAD" if player.position.x<74 else "THE WHISPERING WOODS" if player.position.x<119 else "THE HOLLOW OAK" if player.position.x<161 else "MUSHROOM GROTTO" if player.position.x<203 else "HUNTER’S CAMP" if player.position.x<245 else "ANCIENT RUINS"
	if next_region!=region:
		region = next_region
		region_timer = 3.5
	region_timer = maxf(0,region_timer-dt)
	region_label.text = region if region_timer>0 else ""
	door_cooldown = maxf(0,door_cooldown-dt)
	var enter := pressed(KEY_E) or pressed(KEY_UP)
	for door: Dictionary in doors:
		var p: Vector3 = door["p"]
		if player.position.distance_to(p)<1.8 and enter and door_cooldown<=0:
			if door["requirement"]=="dash" and not dash_unlocked:
				region_label.text = "Requires Wings of Freedom"
				break
			player.position = door["target"]
			player.velocity = Vector3.ZERO
			room_id = door["room"]
			if not discovered_rooms.has(room_id):
				discovered_rooms.append(room_id)
			spawn = player.position
			camera.position.x = player.position.x
			camera.position.y = player.position.y+1
			door_cooldown = 0.8
			save_progress()
			break
	room_map.text = "REALM 1  |  ROOM "+room_id+"  |  Rooms discovered: "+str(discovered_rooms.size())+" / 5"
	if room_id=="1.1":
		player.position.x = clampf(player.position.x,-4.5,287.5)
	for e in enemies:
		var home: float = e.get_meta("home")
		var kind: int = e.get_meta("kind")
		var is_boss: bool = e.get_meta("boss")
		var state: String = e.get_meta("state")
		var timer: float = maxf(0,float(e.get_meta("timer"))-dt)
		var stun: float = maxf(0,float(e.get_meta("stun"))-dt)
		var distance := absf(player.position.x-e.position.x)
		var direction := signf(player.position.x-e.position.x)
		var desired := 0.0
		if stun>0:
			desired = e.velocity.x*0.85
		elif state=="warn":
			if timer<=0:
				state = "strike"
				timer = 0.48 if is_boss else 0.25 if kind==0 else 0.38
				if is_boss and int(e.get_meta("hp"))<=7:
					e.velocity.y = 7.5
		elif state=="strike":
			desired = float(e.get_meta("dir"))*((11.0 if int(e.get_meta("hp"))<=7 else 8.0) if is_boss else 8.0 if kind==0 else 6.5 if kind==1 else 3.8)
			if timer<=0:
				state = "recover"
				timer = 0.65 if kind==0 else 0.9 if kind==1 else 1.2
		elif state=="recover":
			if timer<=0:
				state = "patrol"
		else:
			if distance<(3.2 if is_boss else 2.3) and absf(player.position.y-e.position.y)<1.0:
				state = "warn"
				timer = 0.28 if kind==0 else 0.42 if kind==1 else 0.65
				e.set_meta("dir",direction)
			elif distance<6.0:
				desired = direction*(4.6 if kind==0 else 3.4 if kind==1 else 2.0)
			else:
				desired = clampf(home-e.position.x,-1.0,1.0)
		e.set_meta("state",state)
		e.set_meta("timer",timer)
		e.set_meta("stun",stun)
		e.velocity.x = move_toward(e.velocity.x,desired,24*dt)
		var model: Node3D = e.get_meta("model")
		model.call("animate",dt,e.velocity.x,state)
		if is_boss:
			model.scale *= 1.8
		var label: Label3D = e.get_meta("label")
		label.text = ("!  " if state=="warn" else "")+("" if is_boss else "♥".repeat(int(e.get_meta("hp"))) )
		label.modulate = Color.ORANGE_RED if state=="warn" else Color.WHITE
		e.velocity.y -= 20*dt
		e.move_and_slide()
		e.position.z = 0
		if e.position.y < -8:
			e.position = Vector3(home,-2.5 if home>43 and home<54 else 2.0,0)
			e.velocity = Vector3.ZERO
		if e.position.distance_to(player.position)<(1.45 if is_boss else 1.0) and invulnerable <= 0 and state=="strike":
			hp -= 1
			game_menu.call("sound","hurt")
			shake = 0.18
			invulnerable = 1.2
			player.velocity = Vector3(-facing*6,5,0)
	if player.position.y < -9 or hp <= 0:
		dash_time = 0
		dash_ready = true
		double_ready = true
		player.position = spawn
		player.velocity = Vector3.ZERO
		hp = max_hp
		invulnerable = 1.5
	if pressed(KEY_R):
		dash_time = 0
		dash_ready = true
		double_ready = true
		player.position = spawn
		player.velocity = Vector3.ZERO
		hp = max_hp
		return
	camera.position.x = lerpf(camera.position.x,player.position.x+facing*2,dt*5)
	camera.position.y = lerpf(camera.position.y,player.position.y+1.0,dt*5)
	if shake>0:
		camera.position.x += randf_range(-0.08,0.08)
		camera.position.y += randf_range(-0.08,0.08)
	boss_label.text = "IRON ROOSTER  "+str(boss.get_meta("hp"))+"/14" if is_instance_valid(boss) and not boss_done and player.position.x>58 and player.position.x<74 else "IRON ROOSTER DEFEATED — ROAD OPEN" if boss_done and player.position.x>58 and player.position.x<74 else ""
	hud.text = "RESCUE PRINCESS TINA  |  %s  |  Corn: %d  |  Enemies: %d\nA/D or arrows: move   Space: jump   J: combo   K: punch   L: flap   C: dodge   R: checkpoint   Esc: pause   E/Up: doorway   Shift: dash   F: fork\n%s" % ["♥".repeat(hp)+"♡".repeat(max_hp-hp),corn,enemies.size(),(attack_name+"  COMBO "+str(combo) if combo>0 else attack_name) if attack_timer>0 else "Wings of Freedom: "+("READY" if dash_ready else "RECHARGING") if dash_unlocked else "Explore the realm to discover Wings of Freedom"]

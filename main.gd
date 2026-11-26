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
var facing := 1.0
var cooldown := 0.0
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
	var m := mesh(parent, SphereMesh.new(), pos, color)
	m.scale = size
	return m

func platform(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	add_child(body)
	body.position = pos
	var box := BoxMesh.new()
	box.size = size
	mesh(body, box, Vector3.ZERO, Color("#746044"))
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	var grass := BoxMesh.new()
	grass.size = Vector3(size.x, 0.12, size.z)
	mesh(body, grass, Vector3(0, size.y / 2, 0), Color("#82984c"))

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

func expansion() -> void:
	for i in range(12):
		var x := 123.0+float(i)*14.0
		platform(Vector3(x,-0.5,0),Vector3(10,1,5))
		platform(Vector3(x+7,-5.5,0),Vector3(14,1,5))
		platform(Vector3(x-3,2,0),Vector3(3,0.4,3))
		platform(Vector3(x+1,4,0),Vector3(3,0.4,3))
		platform(Vector3(x+5,6,0),Vector3(3,0.4,3))
		platform(Vector3(x+8,-2.5,0),Vector3(2,0.4,3))
		kernel(Vector3(x+5,6.8,0))
		kernel(Vector3(x+7,-4.2,0))
		var mushroom := Node3D.new()
		add_child(mushroom)
		mushroom.position = Vector3(x+3,0.4,0)
		ball(mushroom,Vector3.ZERO,Vector3(1.4,0.55,1.2),Color("#e75a76"))
		ball(mushroom,Vector3(0,0.25,0),Vector3(0.35,0.12,0.35),Color("#ffe4ae"))
		mushrooms.append(mushroom)
		var crate := Node3D.new()
		add_child(crate)
		crate.position = Vector3(x-2,0.6,0)
		var box := BoxMesh.new()
		box.size = Vector3(0.85,0.85,0.85)
		mesh(crate,box,Vector3.ZERO,Color("#b67e43"))
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
			lift(Vector3(x+6,-4,0),Vector3(0,8,0),float(i))
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
	env.environment.background_color = Color("#e6b98c")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.55
	env.environment.ambient_light_color = Color("#d8e5ff")
	add_child(env)
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.shadow_enabled = true
	sun.light_color = Color("#ffe0ae")
	sun.light_energy = 1.3
	var rim := DirectionalLight3D.new()
	add_child(rim)
	rim.rotation_degrees = Vector3(-25,145,0)
	rim.light_color = Color("#9acbff")
	rim.light_energy = 0.45
	platform(Vector3(0,-0.5,0),Vector3(10,1,5))
	platform(Vector3(10,-0.5,0),Vector3(6,1,5))
	platform(Vector3(7,-4.5,0),Vector3(24,1,5))
	platform(Vector3(2,-2.3,0),Vector3(2,0.4,3))
	platform(Vector3(13,-2.4,0),Vector3(2,0.4,3))
	platform(Vector3(19,-2.0,0),Vector3(3,0.4,3))
	platform(Vector3(4,2.0,0),Vector3(3,0.4,3))
	platform(Vector3(8,4.0,0),Vector3(3,0.4,3))
	platform(Vector3(12,5.8,0),Vector3(4,0.4,3))
	platform(Vector3(17,5.8,0),Vector3(3,0.4,3))
	platform(Vector3(31,5.8,0),Vector3(4,0.4,3))
	platform(Vector3(32,7.7,0),Vector3(3,0.4,3))
	platform(Vector3(35,9.5,0),Vector3(5,0.4,3))
	platform(Vector3(36,8.0,0),Vector3(4,0.4,3))
	platform(Vector3(41,6.0,0),Vector3(4,0.4,3))
	platform(Vector3(46,4.0,0),Vector3(4,0.4,3))
	platform(Vector3(51,2.0,0),Vector3(4,0.4,3))
	shrine = Node3D.new()
	add_child(shrine)
	shrine.position = Vector3(12,6.7,0)
	for side in [-1.0,1.0]:
		var feather := ball(shrine,Vector3(side*0.3,0,0),Vector3(0.3,0.95,0.2),Color("#a9eaff"))
		feather.rotation.z = side*-0.6
	var hint := Label3D.new()
	shrine.add_child(hint)
	hint.position.y = 0.8
	hint.text = "WINGS OF FREEDOM"
	hint.font_size = 40
	hint.pixel_size = 0.006
	for p in [Vector3(6,-3.3,0),Vector3(10,-3.3,0),Vector3(15,-3.3,0),Vector3(17,6.5,0),Vector3(31,6.5,0),Vector3(35,10.2,0),Vector3(36,8.7,0),Vector3(46,4.7,0)]:
		kernel(p)
	platform(Vector3(17,-0.5,0),Vector3(6,1,5))
	platform(Vector3(29.5,-0.5,0),Vector3(19,1,5))
	platform(Vector3(8,1.3,0),Vector3(3,0.4,3))
	platform(Vector3(12,2.7,0),Vector3(3,0.4,3))
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
	platform(Vector3(87,-5.5,0),Vector3(14,1,5))
	platform(Vector3(104,-5.5,0),Vector3(20,1,5))
	platform(Vector3(79,2.0,0),Vector3(3,0.4,3))
	platform(Vector3(84,4.0,0),Vector3(3,0.4,3))
	platform(Vector3(97,4.0,0),Vector3(4,0.4,3))
	platform(Vector3(102,6.0,0),Vector3(4,0.4,3))
	platform(Vector3(109,4.0,0),Vector3(4,0.4,3))
	platform(Vector3(91,-3.0,0),Vector3(3,0.4,3))
	lift(Vector3(87,4,0),Vector3(7,0,0),0)
	lift(Vector3(105,-4,0),Vector3(0,5.5,0),1.0)
	lift(Vector3(21,1,0),Vector3(0,4,0),0.5)
	for i in range(5):
		bridge(Vector3(84+float(i)*1.2,-0.1,0))
	spikes(Vector3(87,-4.7,0))
	spikes(Vector3(99,-4.7,0))
	spikes(Vector3(103,0.3,0))
	shortcut = barrier(Vector3(110,-3.6,0),Vector3(0.4,3,3),Color("#84613d"))
	for p in [Vector3(79,2.8,0),Vector3(84,4.8,0),Vector3(97,4.8,0),Vector3(102,6.8,0),Vector3(109,4.8,0),Vector3(92,-2.2,0),Vector3(107,-4.2,0)]:
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
	platform(Vector3(33,5.5,0),Vector3(4,0.4,3))
	secret_wall = barrier(Vector3(34.8,6.7,0),Vector3(0.4,2.1,3),Color("#89603d"))
	chest = Node3D.new()
	add_child(chest)
	chest.position = Vector3(35,6.0,0)
	var chest_box := BoxMesh.new()
	chest_box.size = Vector3(0.7,0.5,0.55)
	mesh(chest,chest_box,Vector3.ZERO,Color("#b88a39"))
	gate = barrier(Vector3(72,2,0),Vector3(0.4,4,4),Color("#56636b"))
	for p in [Vector3(3,0.8,0),Vector3(8,2,0),Vector3(12,3.4,0),Vector3(24,2,0),Vector3(28,3.4,0),Vector3(32,4.8,0),Vector3(44,-2.8,0),Vector3(49,-2.8,0),Vector3(56,-1.5,0)]:
		kernel(p)
	add_child(preload("res://farmstead.gd").new())
	ball(self,Vector3(17,0.3,-0.8),Vector3(1.2,0.35,0.8),Color("#e8cb71"))
	ball(self,Vector3(47,-3.2,-0.8),Vector3(1.2,0.35,0.8),Color("#e8cb71"))
	expansion()
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
	file.store_var({"spawn":spawn,"corn":corn,"max_hp":max_hp,"checkpoint":checkpoint,"cellar":cellar_checkpoint,"boss":boss_done,"secret":secret_open,"reward":reward_taken,"collected":collected,"defeated":defeated,"dash":dash_unlocked,"shortcut":shortcut_open,"woods":woods_checkpoint,"double":double_unlocked,"fork":fork_unlocked,"camps":visited_camps})

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

func attack(kind: String, reach: float, damage: int, push: float) -> void:
	if cooldown > 0:
		return
	cooldown = 0.15 if kind == "Peck" else 0.30
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
			shake = 0.12
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
	cooldown = maxf(0,cooldown-dt)
	invulnerable = maxf(0,invulnerable-dt)
	attack_timer = maxf(0,attack_timer-dt)
	clock += dt
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
		player.velocity.y = 11.5
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
	if player.velocity.y>3 and not Input.is_physical_key_pressed(KEY_SPACE) and not Input.is_joy_button_pressed(0,JOY_BUTTON_A):
		player.velocity.y = move_toward(player.velocity.y,3,35*dt)
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
	var next_region := "THE OLD FARMYARD" if player.position.x<21 else "THE DERELICT BARN" if player.position.x<39 else "THE FORGOTTEN CELLAR" if player.position.x<58 else "THE IRON ROOSTER" if not boss_done else "HUNTERS' ROAD" if player.position.x<74 else "THE WHISPERING WOODS" if player.position.x<119 else "THE HOLLOW OAK" if player.position.x<161 else "MUSHROOM GROTTO" if player.position.x<203 else "HUNTER’S CAMP" if player.position.x<245 else "ANCIENT RUINS"
	if next_region!=region:
		region = next_region
		region_timer = 3.5
	region_timer = maxf(0,region_timer-dt)
	region_label.text = region if region_timer>0 else ""
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
				timer = 0.65 if is_boss else 0.25 if kind==0 else 0.38
		elif state=="strike":
			desired = float(e.get_meta("dir"))*(7.0 if is_boss else 8.0 if kind==0 else 6.5 if kind==1 else 3.8)
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
		player.position = spawn
		player.velocity = Vector3.ZERO
		hp = max_hp
		invulnerable = 1.5
	if pressed(KEY_R):
		player.position = spawn
		player.velocity = Vector3.ZERO
		hp = max_hp
		return
	camera.position.x = lerpf(camera.position.x,player.position.x+facing*2,dt*5)
	camera.position.y = lerpf(camera.position.y,player.position.y+1.0,dt*5)
	if shake>0:
		camera.position.x += randf_range(-0.08,0.08)
		camera.position.y += randf_range(-0.08,0.08)
	boss_label.text = "IRON ROOSTER  "+str(boss.get_meta("hp"))+"/14" if is_instance_valid(boss) and not boss_done and player.position.x>58 else "IRON ROOSTER DEFEATED — ROAD OPEN" if boss_done and player.position.x>58 and player.position.x<74 else ""
	hud.text = "RESCUE PRINCESS TINA  |  %s  |  Corn: %d  |  Enemies: %d\nA/D or arrows: move   Space: jump   J: peck   K: punch   L: flap   R: checkpoint   Esc: pause   Shift: dash   F: fork\n%s" % ["♥".repeat(hp)+"♡".repeat(max_hp-hp),corn,enemies.size(),attack_name if attack_timer>0 else "Wings of Freedom: "+("READY" if dash_ready else "RECHARGING") if dash_unlocked else "Explore the upper farm to discover Wings of Freedom"]

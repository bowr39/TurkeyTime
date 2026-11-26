extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var hud: Label
var turkey: Node3D
var enemies: Array[CharacterBody3D] = []
var game_menu: CanvasLayer
var collected: Array = []
var defeated: Array = []
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
	n.set_meta("id",str(p.x))
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

func _ready() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("#e6b98c")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.7
	add_child(env)
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.shadow_enabled = true
	platform(Vector3(4,-0.5,0),Vector3(18,1,5))
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
	player = actor(spawn)
	turkey = preload("res://timmy_model.gd").new()
	player.add_child(turkey)
	for x in [5.0, 16.0, 25.0, 34.0, 46.0, 51.0, 65.0]:
		var e := actor(Vector3(x,-2.8 if x>43 and x<54 else 1.0,0))
		var is_boss := x==65.0
		var kind := 2 if is_boss else enemies.size()%3
		var model = preload("res://enemy_model.gd").new()
		model.kind = kind
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
	camera.size = 6.5
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
	file.store_var({"spawn":spawn,"corn":corn,"max_hp":max_hp,"checkpoint":checkpoint,"cellar":cellar_checkpoint,"boss":boss_done,"secret":secret_open,"reward":reward_taken,"collected":collected,"defeated":defeated})

func load_progress() -> void:
	var file := FileAccess.open("user://turkey_time.save",FileAccess.READ)
	if file==null:
		return
	var data = file.get_var()
	if not data is Dictionary:
		return
	spawn = data.get("spawn",Vector3(0,2,0))
	corn = int(data.get("corn",0))
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
		if collected.has(n.get_meta("id")):
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
	cooldown = 0.25 if kind == "Peck" else 0.55
	attack_name = kind
	game_menu.call("sound",kind)
	attack_timer = 0.25
	var tint := Color("#b5eaff") if kind=="Flap" else Color("#ffe3a2")
	burst(player.position+Vector3(facing*reach*0.55,0.15,0.4),tint,10 if kind=="Flap" else 5)
	if not secret_open and kind=="Punch" and player.position.distance_to(Vector3(34.8,6.7,0))<1.8:
		secret_open = true
		secret_wall.queue_free()
		burst(Vector3(34.8,6.7,0),Color("#b88b56"),18)
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
	player.velocity.x = move_toward(player.velocity.x,axis*7.0,55*dt)
	if axis != 0:
		facing = signf(axis)
	turkey.rotation.y = 0 if facing > 0 else PI
	var jump := pressed(KEY_SPACE)
	if jump or Input.is_joy_button_pressed(0,JOY_BUTTON_A):
		jump_buffer = 0.13
	else:
		jump_buffer = maxf(0,jump_buffer-dt)
	if player.is_on_floor():
		coyote = 0.12
	else:
		coyote = maxf(0,coyote-dt)
		player.velocity.y -= 20*dt
	if jump_buffer>0 and coyote>0:
		player.velocity.y = 10
		coyote = 0
		jump_buffer = 0
	if player.velocity.y>3 and not Input.is_physical_key_pressed(KEY_SPACE) and not Input.is_joy_button_pressed(0,JOY_BUTTON_A):
		player.velocity.y = move_toward(player.velocity.y,3,35*dt)
	player.move_and_slide()
	player.position.z = 0
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
	var next_region := "THE OLD FARMYARD" if player.position.x<21 else "THE DERELICT BARN" if player.position.x<39 else "THE FORGOTTEN CELLAR" if player.position.x<58 else "THE IRON ROOSTER" if not boss_done else "HUNTERS' ROAD — COMING SOON"
	if next_region!=region:
		region = next_region
		region_timer = 3.5
	region_timer = maxf(0,region_timer-dt)
	region_label.text = region if region_timer>0 else ""
	player.position.x = clampf(player.position.x,-4.5,72.5)
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
			elif distance<4.0:
				desired = direction*(3.2 if kind==0 else 2.3 if kind==1 else 1.3)
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
	if player.position.y < -8 or hp <= 0:
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
	boss_label.text = "IRON ROOSTER  "+str(boss.get_meta("hp"))+"/14" if is_instance_valid(boss) and not boss_done and player.position.x>58 else "IRON ROOSTER DEFEATED — ROAD OPEN" if boss_done and player.position.x>58 else ""
	hud.text = "RESCUE PRINCESS TINA  |  %s  |  Corn: %d  |  Enemies: %d\nA/D or arrows: move   Space: jump   J: peck   K: punch   L: flap   R: checkpoint   Esc: pause\n%s" % ["♥".repeat(hp)+"♡".repeat(max_hp-hp),corn,enemies.size(),attack_name if attack_timer>0 else ""]

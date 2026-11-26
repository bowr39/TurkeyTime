extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var hud: Label
var turkey: Node3D
var enemies: Array[CharacterBody3D] = []
var hp := 5
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
	platform(Vector3(60,-0.5,0),Vector3(4,1,5))
	add_child(preload("res://farmstead.gd").new())
	ball(self,Vector3(17,0.3,-0.8),Vector3(1.2,0.35,0.8),Color("#e8cb71"))
	ball(self,Vector3(47,-3.2,-0.8),Vector3(1.2,0.35,0.8),Color("#e8cb71"))
	player = actor(spawn)
	turkey = preload("res://timmy_model.gd").new()
	player.add_child(turkey)
	for x in [5.0, 16.0, 25.0, 34.0, 46.0, 51.0]:
		var e := actor(Vector3(x,-2.8 if x>43 else 1.0,0))
		var kind := enemies.size()%3
		var model = preload("res://enemy_model.gd").new()
		model.kind = kind
		e.add_child(model)
		e.set_meta("model",model)
		e.set_meta("kind",kind)
		e.set_meta("hp",[2,3,5][kind])
		e.set_meta("state","patrol")
		e.set_meta("timer",0.0)
		e.set_meta("dir",1.0)
		e.set_meta("stun",0.0)
		var label := Label3D.new()
		label.position = Vector3(0,1.0,0)
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
	attack_timer = 0.25
	for e: CharacterBody3D in enemies.duplicate():
		var delta: Vector3 = e.position - player.position
		if absf(delta.y) < 1.4 and absf(delta.x) <= reach and delta.x*facing >= -0.15:
			e.set_meta("hp",int(e.get_meta("hp"))-damage)
			e.velocity.x = facing*push
			e.set_meta("stun",0.22)
			e.set_meta("state","recover")
			e.set_meta("timer",0.35)
			if int(e.get_meta("hp")) <= 0:
				enemies.erase(e)
				e.queue_free()

func _physics_process(dt: float) -> void:
	cooldown = maxf(0,cooldown-dt)
	invulnerable = maxf(0,invulnerable-dt)
	attack_timer = maxf(0,attack_timer-dt)
	clock += dt
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
		hp = 5
	if not cellar_checkpoint and absf(player.position.x-47)<1.2 and player.position.y<0:
		cellar_checkpoint = true
		spawn = Vector3(47,-2.5,0)
		hp = 5
	var next_region := "THE OLD FARMYARD" if player.position.x<21 else "THE DERELICT BARN" if player.position.x<39 else "THE FORGOTTEN CELLAR" if player.position.x<58 else "HUNTERS' ROAD — COMING SOON"
	if next_region!=region:
		region = next_region
		region_timer = 3.5
	region_timer = maxf(0,region_timer-dt)
	region_label.text = region if region_timer>0 else ""
	player.position.x = clampf(player.position.x,-4.5,61.0)
	for e in enemies:
		var home: float = e.get_meta("home")
		var kind: int = e.get_meta("kind")
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
				timer = 0.25 if kind==0 else 0.38
		elif state=="strike":
			desired = float(e.get_meta("dir"))*(8.0 if kind==0 else 6.5 if kind==1 else 3.8)
			if timer<=0:
				state = "recover"
				timer = 0.65 if kind==0 else 0.9 if kind==1 else 1.2
		elif state=="recover":
			if timer<=0:
				state = "patrol"
		else:
			if distance<2.3 and absf(player.position.y-e.position.y)<1.0:
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
		var label: Label3D = e.get_meta("label")
		label.text = ("!  " if state=="warn" else "")+"♥".repeat(int(e.get_meta("hp")))
		label.modulate = Color.ORANGE_RED if state=="warn" else Color.WHITE
		e.velocity.y -= 20*dt
		e.move_and_slide()
		e.position.z = 0
		if e.position.y < -8:
			e.position = Vector3(home,-2.5 if home>43 else 2.0,0)
			e.velocity = Vector3.ZERO
		if e.position.distance_to(player.position)<1.0 and invulnerable <= 0 and state=="strike":
			hp -= 1
			invulnerable = 1.2
			player.velocity = Vector3(-facing*6,5,0)
	if player.position.y < -8 or hp <= 0:
		player.position = spawn
		player.velocity = Vector3.ZERO
		hp = 5
		invulnerable = 1.5
	if pressed(KEY_R):
		get_tree().reload_current_scene()
		return
	camera.position.x = lerpf(camera.position.x,player.position.x+facing*2,dt*5)
	camera.position.y = lerpf(camera.position.y,player.position.y+1.0,dt*5)
	hud.text = "RESCUE PRINCESS TINA  |  %s  |  Enemies: %d\nA/D or arrows: move   Space: jump   J: peck   K: punch   L: flap   R: restart\n%s" % ["♥".repeat(hp)+"♡".repeat(5-hp),enemies.size(),attack_name if attack_timer>0 else ""]

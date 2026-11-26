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
	platform(Vector3(25,-0.5,0),Vector3(7,1,5))
	platform(Vector3(8,1.3,0),Vector3(3,0.4,3))
	platform(Vector3(12,2.7,0),Vector3(3,0.4,3))
	platform(Vector3(30,1.2,0),Vector3(3,0.4,3))
	for i in range(19):
		var x := float(i)*3.2-12.0
		var trunk := CylinderMesh.new()
		trunk.height = 3.8
		mesh(self,trunk,Vector3(x,1.4,-6),Color("#76503b"))
		ball(self,Vector3(x,3.7,-6),Vector3(3.2,3.4,2.6),Color("#b96932") if i%2==0 else Color("#d99b36"))
	for i in range(15):
		ball(self,Vector3(float(i)*2.1-3,0.2,-1.6),Vector3(0.65,0.48,0.65),Color("#e28a25"))
	var barn := BoxMesh.new()
	barn.size = Vector3(6,4,2)
	mesh(self,barn,Vector3(3,2,-8),Color("#9a463b"))
	var roof := PrismMesh.new()
	roof.size = Vector3(7,2,3)
	mesh(self,roof,Vector3(3,5,-8),Color("#583d38"))
	ball(self,Vector3(17,0.3,-0.8),Vector3(1.2,0.35,0.8),Color("#e8cb71"))
	player = actor(spawn)
	turkey = Node3D.new()
	player.add_child(turkey)
	ball(turkey,Vector3.ZERO,Vector3(1.2,1,0.9),Color("#795039"))
	ball(turkey,Vector3(0.43,0.55,0),Vector3(0.42,0.65,0.42),Color("#b95c46"))
	ball(turkey,Vector3(0.63,0.57,0),Vector3(0.4,0.2,0.22),Color("#e8aa38"))
	ball(turkey,Vector3(0.52,0.69,0.18),Vector3(0.12,0.12,0.12),Color.BLACK)
	for side in [-1.0,1.0]:
		wings.append(ball(turkey,Vector3(-0.12,0.05,side*0.4),Vector3(0.8,0.38,0.22),Color("#ad7547")))
		ball(turkey,Vector3(0.12,-0.52,side*0.23),Vector3(0.42,0.13,0.18),Color("#e2a24b"))
	ball(turkey,Vector3(0.48,0.26,0.05),Vector3(0.18,0.35,0.18),Color("#a82e31"))
	for i in range(7):
		var feather := ball(turkey,Vector3(-0.52,0.3,float(i-3)*0.16),Vector3(0.24,1.2,0.23),Color("#a66a42"))
		feather.rotation_degrees.x = float(i-3)*18
	for x in [5.0, 16.0, 25.0]:
		var e := actor(Vector3(x,1,0))
		ball(e,Vector3.ZERO,Vector3(0.9,0.9,0.9),Color("#a74636"))
		e.set_meta("hp",3)
		e.set_meta("home",x)
		enemies.append(e)
	camera = Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 9
	camera.position = Vector3(2,3,15)
	camera.current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	layer.add_child(hud)
	hud.position = Vector2(20,20)
	hud.add_theme_font_size_override("font_size",22)

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
	for wing in wings:
		wing.rotation.x = sin(clock*24)*0.7 if attack_timer>0 else 0.1*sin(clock*3)
	if not checkpoint and absf(player.position.x-17)<1.2 and player.position.y<2:
		checkpoint = true
		spawn = Vector3(17,2,0)
		hp = 5
	for e in enemies:
		var home: float = e.get_meta("home")
		var target := player.position.x if absf(player.position.x-home)<3 else home
		e.velocity.x = move_toward(e.velocity.x,signf(target-e.position.x)*1.7,5*dt)
		e.velocity.y -= 20*dt
		e.move_and_slide()
		e.position.z = 0
		if e.position.y < -8:
			e.position = Vector3(home,2,0)
			e.velocity = Vector3.ZERO
		if e.position.distance_to(player.position)<0.95 and invulnerable <= 0:
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
	camera.position.y = lerpf(camera.position.y,maxf(3,player.position.y+1),dt*5)
	hud.text = "RESCUE PRINCESS TINA  |  Health: %d/5  |  Enemies: %d\nA/D or arrows: move   Space: jump   J: peck   K: punch   L: flap   R: restart\n%s" % [hp,enemies.size(),attack_name if attack_timer>0 else ""]

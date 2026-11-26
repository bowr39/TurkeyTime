extends Node3D

var rng := RandomNumberGenerator.new()
var materials: Dictionary = {}

func mat(tint: Color, glow: bool = false) -> StandardMaterial3D:
	var key := str(tint)+str(glow)
	if materials.has(key):
		return materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.roughness = 0.88
	if glow:
		m.emission_enabled = true
		m.emission = tint
		m.emission_energy_multiplier = 1.4
	materials[key] = m
	return m

func piece(shape: Mesh,p: Vector3,scale_value: Vector3,tint: Color,glow: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = shape
	n.material_override = mat(tint,glow)
	add_child(n)
	n.position = p
	n.scale = scale_value
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return n

func orb(p: Vector3,s: Vector3,tint: Color,glow: bool = false) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radial_segments = 10
	shape.rings = 6
	return piece(shape,p,s,tint,glow)

func block(p: Vector3,s: Vector3,tint: Color) -> MeshInstance3D:
	return piece(BoxMesh.new(),p,s,tint)

func branch(a: Vector3,b: Vector3,r: float,tint: Color) -> void:
	var shape := CylinderMesh.new()
	shape.top_radius = r*0.55
	shape.bottom_radius = r
	shape.height = a.distance_to(b)
	shape.radial_segments = 8
	var n := piece(shape,(a+b)*0.5,Vector3.ONE,tint)
	n.quaternion = Quaternion(Vector3.UP,(b-a).normalized())

func tree(x: float,y: float,z: float,h: float,palette: Array[Color]) -> void:
	var root := Vector3(x,y,z)
	var crown := root+Vector3(rng.randf_range(-1,1),h,0)
	var bark := Color("#493a36") if z> -8 else Color("#485951")
	branch(root,crown,h*0.085,bark)
	for i in range(4):
		var side := -1.0 if i%2==0 else 1.0
		var tip := crown+Vector3(side*rng.randf_range(1.0,2.5),rng.randf_range(-1.2,0.8),rng.randf_range(-0.8,0.8))
		branch(root.lerp(crown,0.55+float(i)*0.08),tip,h*0.035,bark.lightened(0.08))
		for j in range(3):
			orb(tip+Vector3(rng.randf_range(-1.1,1.1),rng.randf_range(-0.5,0.7),rng.randf_range(-0.7,0.7)),Vector3(rng.randf_range(2.1,3.8),rng.randf_range(1.6,2.8),2.3),palette[(i+j)%palette.size()])
	for i in range(3):
		branch(root+Vector3(0,0.8,0),root+Vector3(float(i-1)*1.2,-0.15,0.4),0.18,bark)

func ruin(x: float,y: float) -> void:
	var z := -3.2
	for side in [-1.0,1.0]:
		for i in range(7):
			var p := Vector3(x+side*1.65,y+float(i)*0.56,z)
			block(p,Vector3(0.82,0.52,0.8),Color("#777c70").lightened(rng.randf_range(-0.06,0.15)))
			if i%2==0:
				orb(p+Vector3(0,0.15,0.45),Vector3(0.75,0.16,0.12),Color("#667b43"))
	for i in range(9):
		var angle := float(i)*PI/8
		var p := Vector3(x+cos(angle)*1.65,y+3.4+sin(angle)*1.65,z)
		var stone := block(p,Vector3(0.65,0.62,0.8),Color("#9a9780"))
		stone.rotation.z = angle-PI/2

func _ready() -> void:
	rng.seed = 8421
	var autumn: Array[Color] = [Color("#b36a35"),Color("#db9a42"),Color("#8e4934"),Color("#c57e36")]
	var green: Array[Color] = [Color("#426b50"),Color("#688b4d"),Color("#92a65b"),Color("#355a49")]
	var violet: Array[Color] = [Color("#4f536e"),Color("#77618b"),Color("#a078a1"),Color("#526f72")]
	for i in range(25):
		var x := float(i)*11.5
		tree(x,-1,-9,rng.randf_range(8,12),green)
	for i in range(35):
		var x := 74.0+float(i)*6.0
		tree(x,-0.8,-3.8,rng.randf_range(5.5,9),green if x<161 else violet if x<203 else autumn)
	for i in range(36):
		var x := 75.0+float(i)*5.8
		var tint := Color("#e4aa55") if x<161 else Color("#b78cf2") if x<203 else Color("#dfad72")
		for j in range(3):
			var p := Vector3(x+float(j)*0.32,0.15,-1.6)
			branch(p,p+Vector3(0,0.38,0),0.035,Color("#6e8450"))
			orb(p+Vector3(0,0.42,0),Vector3(0.23,0.16,0.23),tint,x>=161 and x<203)
	for x in [249.0,260.0,274.0,283.0]:
		ruin(x,0)
	for i in range(16):
		var x := 162.0+float(i)*2.5
		var h := rng.randf_range(0.7,2.0)
		branch(Vector3(x,0,-2.7),Vector3(x,h,-2.7),0.16,Color("#c5a9a3"))
		orb(Vector3(x,h,-2.7),Vector3(1.7,0.65,1.4),Color("#a56ac3"),true)

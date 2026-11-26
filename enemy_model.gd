extends Node3D
var kind := 0
var champion := false
var tail: Node3D
var wing_joints: Array[Node3D] = []
var limbs: Array[Node3D] = []
var head: Node3D
var time := 0.0

func oval(p: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = SphereMesh.new()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	n.material_override = mat
	p.add_child(n)
	n.position = pos
	n.scale = size
	return n

func box(p: Node3D,pos: Vector3,size: Vector3,color: Color) -> MeshInstance3D:
	var n := oval(p,pos,size,color)
	n.mesh = BoxMesh.new()
	return n

func joint(p: Vector3) -> Node3D:
	var n := Node3D.new()
	add_child(n)
	n.position = p
	return n

func feather(p: Node3D,pos: Vector3,length: float,width: float,angle: float,tint: Color) -> void:
	var n := oval(p,pos,Vector3(width,length,width*0.45),tint)
	n.rotation.z = angle
	oval(n,Vector3(0,0,0.43),Vector3(0.12,0.85,0.1),tint.lightened(0.25))

func beak(p: Node3D,pos: Vector3,length: float,radius: float,tint: Color) -> void:
	var n := oval(p,pos,Vector3.ONE,tint)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = radius
	cone.height = length
	n.mesh = cone
	n.rotation.z = -PI/2

func rooster() -> void:
	var bronze := Color("#c56a29")
	var gold := Color("#f2ad45")
	var teal := Color("#174b4a")
	oval(self,Vector3(-0.12,0.05,0),Vector3(1.15,0.92,0.78),bronze)
	oval(self,Vector3(0.28,0.18,0),Vector3(0.68,0.94,0.68),Color("#713b27"))
	oval(self,Vector3(0.35,0.48,0),Vector3(0.53,0.88,0.51),gold)
	head.position = Vector3(0.48,0.85,0)
	oval(head,Vector3.ZERO,Vector3(0.55,0.52,0.48),gold)
	beak(head,Vector3(0.35,-0.02,0),0.35,0.15,Color("#f9c653"))
	beak(head,Vector3(0.29,-0.13,0),0.24,0.09,Color("#c8872e"))
	for i in range(5):
		var crest := oval(head,Vector3(-0.21+float(i)*0.095,0.26+sin(float(i)*0.7)*0.08,0),Vector3(0.16,0.34,0.13),Color("#c92e37"))
		crest.rotation.z = 0.22
	for side in [-1.0,1.0]:
		oval(head,Vector3(0.13,-0.26,side*0.09),Vector3(0.22,0.36,0.16),Color("#b71e32"))
		oval(head,Vector3(0.10,0.07,side*0.22),Vector3(0.20,0.19,0.09),Color("#fff0bd"))
		oval(head,Vector3(0.15,0.07,side*0.265),Vector3(0.09,0.12,0.04),Color("#16191a"))
		var brow := oval(head,Vector3(0.10,0.17,side*0.25),Vector3(0.24,0.09,0.07),Color("#80321f"))
		brow.rotation.z = -0.28
		var wing := joint(Vector3(-0.10,0.18,side*0.34))
		wing_joints.append(wing)
		oval(wing,Vector3.ZERO,Vector3(0.82,0.62,0.23),Color("#914626"))
		for i in range(5):
			feather(wing,Vector3(-0.16-float(i)*0.09,-0.12+float(i)*0.035,side*0.08),0.64,0.17,-0.95,bronze.lightened(float(i)*0.045))
		if champion:
			oval(wing,Vector3(0.08,0.10,side*0.15),Vector3(0.52,0.36,0.10),Color("#657680"))
			oval(wing,Vector3(0.08,0.10,side*0.21),Vector3(0.20,0.20,0.05),Color("#e0b65d"))
	tail = joint(Vector3(-0.55,0.25,0))
	for i in range(7):
		var offset := float(i-3)
		feather(tail,Vector3(-0.35-absf(offset)*0.055,0.48+float(i%3)*0.12,offset*0.085),1.35-absf(offset)*0.09,0.22,0.65+offset*0.08,teal.lightened(float(i)*0.035))
		feather(tail,Vector3(-0.65,0.38,offset*0.085),0.95,0.19,1.25,Color("#233e50"))
	if champion:
		oval(self,Vector3(0.34,0.12,0),Vector3(0.52,0.65,0.69),Color("#52636e"))
		for i in range(3):
			oval(self,Vector3(0.55,0.30-float(i)*0.19,0),Vector3(0.09,0.10,0.13),Color("#e5b95d"))

func _ready() -> void:
	head = joint(Vector3(0.34,0.08,0))
	if kind == 0:
		var fur := Color("#77717b")
		oval(self,Vector3(-0.1,-0.12,0),Vector3(1.05,0.58,0.64),fur)
		oval(head,Vector3.ZERO,Vector3(0.55,0.45,0.48),fur)
		oval(head,Vector3(0.25,-0.07,0),Vector3(0.38,0.24,0.25),fur)
		oval(head,Vector3(0.43,-0.07,0),Vector3(0.12,0.11,0.12),Color("#d89998"))
		for side in [-1.0,1.0]:
			oval(head,Vector3(-0.08,0.24,side*0.16),Vector3(0.25,0.29,0.12),Color("#c6949a"))
		for i in range(9):
			oval(self,Vector3(-0.52-float(i)*0.075,-0.12+sin(float(i)*0.3)*0.14,0),Vector3(0.18,0.075,0.075),Color("#b78d8b"))
	elif kind == 1:
		rooster()
	else:
		box(self,Vector3.ZERO,Vector3(1.15,0.72,0.72),Color("#526570"))
		box(self,Vector3(-0.15,0.37,0),Vector3(0.65,0.2,0.78),Color("#9b9d91"))
		box(head,Vector3(0.13,0.13,0),Vector3(0.6,0.5,0.56),Color("#34444c"))
		box(head,Vector3(0.43,0.13,0),Vector3(0.05,0.13,0.43),Color("#ff5330"))
		for side in [-1.0,1.0]:
			box(self,Vector3(0,0,side*0.4),Vector3(0.85,0.4,0.14),Color("#a07d45"))
	for side in [-1.0,1.0]:
		if kind == 0:
			oval(head,Vector3(0.15,0.1,side*0.2),Vector3(0.1,0.1,0.06),Color("#19151b"))
		var leg := joint(Vector3(0.1,-0.22,side*0.24))
		limbs.append(leg)
		oval(leg,Vector3(0,-0.15,0),Vector3(0.16,0.35,0.16),Color("#ad8252") if kind!=2 else Color("#39464e"))
		oval(leg,Vector3(0.08,-0.31,0),Vector3(0.28,0.12,0.2),Color("#ad8252") if kind!=2 else Color("#39464e"))

		if kind == 1:
			for toe in range(3):
				var claw := oval(leg,Vector3(0.18,-0.32, float(toe-1)*0.09),Vector3(0.28,0.07,0.065),Color("#e0aa48"))
				claw.rotation.y = float(toe-1)*0.3
			beak(leg,Vector3(-0.13,-0.19,0),0.18,0.055,Color("#e9d6a3"))

func animate(dt: float,speed: float,state: String) -> void:
	time += dt
	for i in range(limbs.size()):
		limbs[i].rotation.z = sin(time*16+float(i)*PI)*clampf(absf(speed)*0.2,0,0.7)
	head.rotation.z = 0.3 if state=="warn" else -0.35 if state=="strike" else 0.0
	scale = Vector3(1.08,0.85,1) if state=="warn" else Vector3.ONE
	if kind == 1:
		tail.rotation.z = sin(time*5)*0.09
		for wing: Node3D in wing_joints:
			wing.rotation.z = -0.65 if state=="strike" else 0.3 if state=="warn" else sin(time*8)*0.06
	if absf(speed)>0.1 and state!="warn":
		rotation.y = 0 if speed>0 else PI

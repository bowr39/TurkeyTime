extends Node3D
var kind := 0
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
		oval(self,Vector3(-0.08,0,0),Vector3(0.95,0.85,0.7),Color("#c58b43"))
		head.position.y = 0.4
		oval(head,Vector3.ZERO,Vector3(0.43,0.5,0.4),Color("#e6bd76"))
		oval(head,Vector3(0.28,-0.02,0),Vector3(0.35,0.16,0.2),Color("#e8a32c"))
		for i in range(4):
			oval(head,Vector3(-0.12+float(i)*0.09,0.28,0),Vector3(0.13,0.28,0.12),Color("#b82932"))
		for i in range(5):
			var f := oval(self,Vector3(-0.45,0.28,float(i-2)*0.1),Vector3(0.23,0.95,0.18),Color("#31594e"))
			f.rotation.z = 0.7
		for side in [-1.0,1.0]:
			oval(self,Vector3(-0.1,0,side*0.32),Vector3(0.6,0.4,0.15),Color("#99562f"))
	else:
		box(self,Vector3.ZERO,Vector3(1.15,0.72,0.72),Color("#526570"))
		box(self,Vector3(-0.15,0.37,0),Vector3(0.65,0.2,0.78),Color("#9b9d91"))
		box(head,Vector3(0.13,0.13,0),Vector3(0.6,0.5,0.56),Color("#34444c"))
		box(head,Vector3(0.43,0.13,0),Vector3(0.05,0.13,0.43),Color("#ff5330"))
		for side in [-1.0,1.0]:
			box(self,Vector3(0,0,side*0.4),Vector3(0.85,0.4,0.14),Color("#a07d45"))
	for side in [-1.0,1.0]:
		if kind != 2:
			oval(head,Vector3(0.15,0.1,side*0.2),Vector3(0.1,0.1,0.06),Color("#19151b"))
		var leg := joint(Vector3(0.1,-0.22,side*0.24))
		limbs.append(leg)
		oval(leg,Vector3(0,-0.15,0),Vector3(0.16,0.35,0.16),Color("#ad8252") if kind!=2 else Color("#39464e"))
		oval(leg,Vector3(0.08,-0.31,0),Vector3(0.28,0.12,0.2),Color("#ad8252") if kind!=2 else Color("#39464e"))

func animate(dt: float,speed: float,state: String) -> void:
	time += dt
	for i in range(limbs.size()):
		limbs[i].rotation.z = sin(time*16+float(i)*PI)*clampf(absf(speed)*0.2,0,0.7)
	head.rotation.z = 0.3 if state=="warn" else -0.35 if state=="strike" else 0.0
	scale = Vector3(1.08,0.85,1) if state=="warn" else Vector3.ONE
	if absf(speed)>0.1 and state!="warn":
		rotation.y = 0 if speed>0 else PI

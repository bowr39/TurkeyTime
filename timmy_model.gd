extends Node3D
# Articulated custom mesh character, facing local +X.
var head: Node3D
var wings: Array[Node3D] = []
var legs: Array[Node3D] = []
var tail: Node3D
var t := 0.0

func part(parent: Node3D, m: Mesh, p: Vector3, c: Color, scale_v := Vector3.ONE) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.85
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	n.material_override = mat
	parent.add_child(n)
	n.position = p
	n.scale = scale_v
	return n

func oval(parent: Node3D,p: Vector3,s: Vector3,c: Color) -> MeshInstance3D:
	return part(parent,SphereMesh.new(),p,c,s)

func pivot(parent: Node3D,p: Vector3) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	n.position = p
	return n

# A tapered, curved feather mesh with a raised central ridge and colored tip.
func feather(parent: Node3D,p: Vector3, length_v: float, width_v: float, angle: float, base: Color, tip: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(10):
		var a := float(i)/10.0
		var b := float(i+1)/10.0
		var wa := width_v*sin(PI*pow(a,0.72))
		var wb := width_v*sin(PI*pow(b,0.72))
		for side in [-1.0,1.0]:
			var verts: Array[Vector3] = [Vector3(0,a*length_v,0.055*sin(a*PI)),Vector3(side*wa,a*length_v,0),Vector3(side*wb,b*length_v,0),Vector3(0,b*length_v,0.055*sin(b*PI))]
			for j in [0,1,2,0,2,3]:
				var v: Vector3 = verts[j]
				var f := v.y/length_v
				st.set_color(tip if f>0.76 else base.darkened(0.15) if f>0.62 else base)
				st.add_vertex(v)
	st.generate_normals()
	var n := part(parent,st.commit(),p,Color.WHITE)
	var mat := n.material_override as StandardMaterial3D
	mat.vertex_color_use_as_albedo = true
	n.rotation.z = angle

func _ready() -> void:
	var bronze := Color("#805035")
	var dark := Color("#493026")
	var gold := Color("#c99152")
	oval(self,Vector3(-0.08,0.03,0),Vector3(1.18,0.92,0.83),dark)
	oval(self,Vector3(0.27,0.05,0),Vector3(0.74,0.82,0.72),bronze)
	tail = pivot(self,Vector3(-0.52,0.08,0))
	for i in range(13):
		var angle := deg_to_rad(-72+float(i)*12)
		feather(tail,Vector3(-0.12,0,-0.18+float(i)*0.025),1.05+0.18*cos(angle),0.145,angle,bronze,gold)
	for i in range(9):
		feather(tail,Vector3(-0.02,0,0.13),0.74,0.115,deg_to_rad(-60+float(i)*15),dark,bronze)
	for side in [-1.0,1.0]:
		var w := pivot(self,Vector3(0.08,0.14,side*0.34))
		wings.append(w)
		oval(w,Vector3(-0.13,-0.06,0),Vector3(0.76,0.43,0.19),bronze)
		for i in range(7):
			feather(w,Vector3(0.08-float(i)*0.065,-0.03,side*0.11),0.48+float(i)*0.025,0.075,deg_to_rad(112+float(i)*7),dark,gold)
		var leg := pivot(self,Vector3(0.08,-0.29,side*0.22))
		legs.append(leg)
		var shin := CylinderMesh.new()
		shin.height = 0.29
		shin.top_radius = 0.045
		shin.bottom_radius = 0.035
		part(leg,shin,Vector3(0,-0.14,0),gold)
		for i in range(3):
			var toe := oval(leg,Vector3(0.09,-0.29,float(i-1)*0.07),Vector3(0.24,0.055,0.055),gold)
			toe.rotation.y = float(i-1)*0.3
	head = pivot(self,Vector3(0.35,0.25,0))
	oval(head,Vector3(0.06,0.16,0),Vector3(0.27,0.57,0.27),Color("#a74939"))
	oval(head,Vector3(0.15,0.43,0),Vector3(0.4,0.36,0.35),Color("#a7a7b5"))
	var beak := CylinderMesh.new()
	beak.top_radius = 0
	beak.bottom_radius = 0.105
	beak.height = 0.27
	var b := part(head,beak,Vector3(0.43,0.39,0),gold)
	b.rotation.z = -PI/2
	oval(head,Vector3(0.29,0.23,0),Vector3(0.13,0.35,0.16),Color("#bd3836"))
	for side in [-1.0,1.0]:
		oval(head,Vector3(0.21,0.47,side*0.15),Vector3(0.13,0.13,0.06),Color("#f4d9a2"))
		oval(head,Vector3(0.24,0.47,side*0.18),Vector3(0.065,0.08,0.035),Color("#171419"))
		var brow := oval(head,Vector3(0.21,0.54,side*0.15),Vector3(0.19,0.055,0.07),dark)
		brow.rotation.z = -0.28

func animate(dt: float,speed: float,grounded: bool,attack: String,remaining: float) -> void:
	t += dt
	var stride := clampf(absf(speed)/7.0,0,1)
	var power := sin(clampf(remaining/0.25,0,1)*PI)
	head.rotation.z = -0.65*power if attack=="Peck" else 0.05*sin(t*7)*stride
	tail.rotation.z = 0.07*sin(t*8)*stride
	for i in range(legs.size()):
		legs[i].rotation.z = sin(t*18+float(i)*PI)*0.75*stride if grounded else -0.35
	for i in range(wings.size()):
		var side := -1.0 if i==0 else 1.0
		wings[i].rotation.x = side*power*1.5 if attack=="Flap" else side*0.12*sin(t*5)
		wings[i].rotation.z = -power*1.2 if attack=="Punch" else 0.12*sin(t*18)*stride
	position.y = 0.045*absf(sin(t*18))*stride if grounded else 0.0

#@tool
extends Node3D

#
#               010           110                         Y
#   Vertices     A0 ---------- B1            Faces      Top    -Z
#           011 /  |      111 /  |                        |   North
#             E4 ---------- F5   |                        | /
#             |    |        |    |          -X West ----- 0 ----- East X
#             |   D3 -------|-- C2                      / |
#             |  /  000     |  / 100               South  |
#             H7 ---------- G6                      Z    Bottom
#              001           101                          -Y

@onready var m : MeshInstance3D = $MeshInstance3D
@onready var slicer : MeshInstance3D = $Player/slice_plane

@onready var lineMesh :=preload("res://addons/line/line_scene.tscn")
@onready var slice_outline : Node3D = $sliceOutline
var size := 1.0

var cut_mode : int = 0

## cutting
var tris : Array = []
var cuts : Array = []

var p_l : Array = []

## cpp
var linecpp

func _ready():
	draw_cube()
	
	linecpp = line.new()
	add_child(linecpp)
	
	linef(Vector3(0,0,0), Vector3(1,0,1), Color.BLACK, 0.0045)

func _input(event):
	if event.is_action_pressed("l_c"):
		var result = preform_slice()

		var new_mesh = result[0]
		m.mesh = new_mesh
		rebuild_tris_from_mesh(new_mesh)

func  _process(delta):
	var t = slicer.global_transform
	var normal = t.basis.z.normalized()
	var d = normal.dot(t.origin)
	var p = Plane(normal,d)

	
	build_preview(p) 
	preview_lines()

func draw_cube():
	tris.clear()
	
	var h = size / 2.0
	
	var vertices := [
		Vector3(-h, h, -h),    ## A0
		Vector3(-h, h, h),     ## E4
		Vector3(-h, -h, h),    ## H7
		Vector3(-h, -h, -h),   ## D3
		
		Vector3(h, h, -h),     ## B1
		Vector3(h, h, h),      ## F5
		Vector3(h, -h, h),     ## G6
		Vector3(h, -h, -h)     ## C2
		
	]


	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)


	## top face
	add_quad(st, vertices[0], vertices[4], vertices[5], vertices[1])
	## left face
	add_quad(st, vertices[2], vertices[3], vertices[0], vertices[1])
	## right face
	add_quad(st, vertices[5], vertices[4], vertices[7], vertices[6])
	## back face
	add_quad(st, vertices[3], vertices[7], vertices[4], vertices[0])
	## front face
	add_quad(st, vertices[2], vertices[1], vertices[5], vertices[6])
	## bottom face
	add_quad(st, vertices[2], vertices[6], vertices[7], vertices[3])

	st.generate_normals()
	m.mesh = st.commit()


func add_quad(st: SurfaceTool, a, b, c, d):
	## tri 1
	add_tri(st, a,b,c)
	tris.append([a,b,c])

	## tri 2
	add_tri(st, a,c,d)
	tris.append([a,c,d])

func add_tri(st: SurfaceTool, a,b,c):
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)

## anything beyond this point i dont understand  :1)

func preform_slice():
	cuts.clear()
	var t = slicer.global_transform
	var normal = t.basis.z.normalized()
	var d = normal.dot(t.origin)
	
	var plane = Plane(normal, d)
	#var plane = Plane(Vector3.UP, 0.0)
	
	var st_a = SurfaceTool.new()
	var st_b = SurfaceTool.new()
	
	st_a.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_b.begin(Mesh.PRIMITIVE_TRIANGLES)
	st_a.set_smooth_group(-1)
	st_b.set_smooth_group(-1)
	
	var count_a : = [0]
	var count_b : = [0]
	
	for i in tris:
		slice_tri(i[0], i[1], i[2], plane, st_a, st_b, count_a, count_b)
	
	draw_cap(st_a,plane, true, count_a, count_b)
	draw_cap(st_b, plane, false, count_a, count_b)
	
	st_a.generate_normals()
	st_b.generate_normals()
	
	var ma = st_a.commit()
	var mb = st_b.commit()
	
	var player_pos = slicer.global_transform.origin
	var side = plane.distance_to(player_pos)

	if side > 0:
		return [mb]
	else:
		return [ma]

func slice_tri(a, b, c, plane: Plane, st_a, st_b, c_a, c_b):
	var da = plane.distance_to(a)
	var db = plane.distance_to(b)
	var dc = plane.distance_to(c)

	if da >= 0 and db >= 0 and dc >= 0:
		add_tri(st_a, a, b, c)
		c_a[0]+= 1
		return
	if da < 0 and db < 0 and dc < 0:
		add_tri(st_b, a, b, c)
		c_b[0] += 1
		return

	var verts = [a, b, c]
	var dists = [da, db, dc]

	var lone_idx = -1
	for i in 3:
		var side_i = dists[i] >= 0
		var side_j = dists[(i + 1) % 3] >= 0
		var side_k = dists[(i + 2) % 3] >= 0
		if side_i != side_j and side_i != side_k:
			lone_idx = i
			break

	var v0 = verts[lone_idx]
	var v1 = verts[(lone_idx + 1) % 3]
	var v2 = verts[(lone_idx + 2) % 3]
	var d0 = dists[lone_idx]
	var d1 = dists[(lone_idx + 1) % 3]
	var d2 = dists[(lone_idx + 2) % 3]

	var i1 = intersect(v0, v1, d0, d1)
	var i2 = intersect(v0, v2, d0, d2)

	cuts.append(i1)
	cuts.append(i2)

	if d0 >= 0:
		add_tri(st_a, v0, i1, i2)
		c_a[0] += 1
		add_tri(st_b, i1, v1, v2)
		c_b[0] += 1
		add_tri(st_b, i1, v2, i2)
		c_b[0] += 1
	else:
		add_tri(st_b, v0, i1, i2)
		c_b[0] += 1
		add_tri(st_a, i1, v1, v2)
		c_a[0] += 1
		add_tri(st_a, i1, v2, i2)
		c_a[0] += 1

func draw_cap(st: SurfaceTool, plane,flip,c_a, c_b):
	if cuts.size() < 3: return

	var n = plane.normal.normalized()
	var t = n.cross(Vector3.UP)

	if t.length() < 0.001:
		t = n.cross(Vector3.RIGHT)
	t = t.normalized()
	var bi_t = n.cross(t)

	var cen = Vector3.ZERO
	for p in cuts:
		cen += p
	cen /= cuts.size()

	var pts_2d : =[]
	for p in cuts:
		var local = p - cen
		var x = local.dot(t)
		var y = local.dot(bi_t)
		pts_2d.append({"p": p, "angle": atan2(y,x)})

	pts_2d.sort_custom(func(a,b): return a.angle < b.angle)

	for i in range(1, pts_2d.size() - 1):
		var p0 = pts_2d[0].p
		var p1 = pts_2d[i].p
		var p2 = pts_2d[i + 1].p

		if flip:
			add_tri(st, p0, p1, p2)
			c_a[0] += 1
		else:
			add_tri(st, p0, p2, p1)
			c_b[0] += 1

func build_preview(plane):
	p_l.clear()

	for tri in tris:
		var a = tri[0]
		var b = tri[1]
		var c = tri[2]

		var da = plane.distance_to(a)
		var db = plane.distance_to(b)
		var dc = plane.distance_to(c)

		var points := [] 

		if da * db < 0:
			points.append(intersect(a, b, da, db))
		if db * dc < 0:
			points.append(intersect(b, c, db, dc))
		if dc * da < 0:
			points.append(intersect(c, a, dc, da))

		if points.size() == 2:
			p_l.append(points)

func preview_lines():
	for c in slice_outline.get_children():
		c.queue_free()

	for seg in p_l:
		linef(seg[0], seg[1], Color.BLACK, 0.0035)

func rebuild_tris_from_mesh(m: ArrayMesh):
	tris.clear()

	var arrays = m.surface_get_arrays(0)
	var verts = arrays[Mesh.ARRAY_VERTEX]

	for i in range(0, verts.size(), 3):
		tris.append([
			verts[i],
			verts[i + 1],
			verts[i + 2]
		])

func intersect(a,b, da, db) -> Vector3:
	var t = da / (da - db)
	return a.lerp(b, t)

## custom line drawing for thickness control
func linef(a:Vector3,b:Vector3, color:Color, thickness:float):
	var l = lineMesh.instantiate()
	slice_outline.add_child(l)

	## material
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	l.material_override = mat
	
	## call cpp
	linecpp.computeLine(a,b,color,thickness,l)

## so we dont have to create a new instance every frame
func updateLine(l, a,b,color, thickness):
	linecpp.computeLine(a,b,color,thickness,l)
	return

extends CharacterBody3D

@onready var parent_ : Node3D = $".."

@onready var head: Node3D = $head
@onready var camera: Camera3D = $head/Camera3D
@onready var cameraOrigin = $head/Camera3D.transform.origin
@onready var col = $CollisionShape3D
@onready var cutter = $slice_plane

var SPEED := 3.8
const JUMP_VELOCITY := 10.0
const GRAVITY := -9.8 * 3

const mouse_sen := 0.07
const rayLen := 5.0

var lerp_speed := 17
var direction = Vector3.ZERO
var b = 0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	##var l = lin

func _input(event: InputEvent):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sen))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sen))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-98), deg_to_rad(98))


func _can_place_voxel_at(pos: Vector3) -> bool:
	var radius = (col.shape as CylinderShape3D).radius
	var height = (col.shape as CylinderShape3D).height
	var xform: Transform3D = col.global_transform
	var player_aabb = AABB(xform.origin - Vector3(radius, height * 0.3, radius), Vector3(radius * 2, height, radius * 2))
	var voxel_aabb: AABB = AABB(pos, Vector3.ONE)
	if player_aabb.intersects(voxel_aabb):
		return false
	return true

func _physics_process(delta):

	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y += GRAVITY * delta

	var input_dir := Input.get_vector("left", "right", "forward", "back")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y))\
	.normalized(), delta * lerp_speed)
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	
	move_and_slide()
	col.scale.y = lerp(col.scale.y,0.82,delta*4)
	
		
	if input_dir.length() > 0: ## walking
		b += delta * 10.0
		var offset_y = sin(b) * 0.01
		var offset_x = cos(b * 0.5) * 0.01 * 0.5 * float(is_on_floor())
		var target = cameraOrigin + Vector3(offset_x, offset_y, 0)
		camera.transform.origin = camera.transform.origin.lerp(target, delta * 10.0)
		#print(camera.transform.origin.y)
	else:
		camera.transform.origin = camera.transform.origin.lerp(cameraOrigin, delta * 10.0)

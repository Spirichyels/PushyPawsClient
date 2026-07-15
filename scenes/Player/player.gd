extends CharacterBody3D

@onready var id_label: Label3D = $IdLabel
@onready var camera_3d: Camera3D = $Camera3D

var camera_yaw: float = 0.0
var camera_pitch: float = 0.0
var camera_distance: float = 3.0
var camera_height: float = 2.0

var is_first_person: bool = false
var sensitivity: float = 2
var is_attacking: bool = false

var rotation_sync_timer: float = 0.0
var last_sent_rotation: float = 0.0

var print_timer = 0.5


func _camera_update():
	var yaw_rad = deg_to_rad(camera_yaw)
	var pitch_rad = deg_to_rad(camera_pitch)
	
	if is_first_person:
		camera_3d.global_position = global_position + Vector3(0, 1.5, 0)
		camera_3d.rotation = Vector3(pitch_rad, yaw_rad, 0)
	else:
		var dir = Vector3(
			sin(yaw_rad) * cos(pitch_rad),
			sin(pitch_rad),
			cos(yaw_rad) * cos(pitch_rad)
		)
		camera_3d.global_position = global_position + Vector3(0, 1.5, 0) - dir * camera_distance
		camera_3d.look_at(global_position + Vector3(0, 1.5, 0))


func _unhandled_input(event: InputEvent) -> void:
	if Network.local_player != self:
		return
	if event is InputEventMouseMotion:
		camera_yaw -= event.relative.x * sensitivity * 0.1
		camera_pitch -= event.relative.y * sensitivity * 0.1
		camera_pitch = clamp(camera_pitch, -90.0, 45.0)
		_camera_update()


func _input(event: InputEvent) -> void:
	if Network.local_player != self:
		return
	if event.is_action_pressed("toggle_view"):
		is_first_person = !is_first_person
		_camera_update()
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not is_attacking:
			is_attacking = true
		Network.send_attack(rotation.y)
		$AnimationPlayer.stop()
		$AnimationPlayer.play("ShoveTwoHands")
		await $AnimationPlayer.animation_finished
		$AnimationPlayer.play("Idle")
		is_attacking = false
	
	if event.is_action_pressed("toggle_ESC"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		get_viewport().set_input_as_handled()


func set_id_label(newId):
	id_label.text = str(newId)


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	if not Network.connected or Network.my_id == -1:
		return
		
	if Network.local_player != self:
		return
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		Network.send_jump()
	
	_camera_update()
	
	var input_dir = Input.get_vector("leftA", "rightD", "downS", "upW")
	
	
	
	var cam_forward = -camera_3d.global_transform.basis.z
	cam_forward.y = 0
	cam_forward = cam_forward.normalized()
	var cam_right = camera_3d.global_transform.basis.x
	cam_right.y = 0
	cam_right = cam_right.normalized()
	
	var move_dir = (cam_forward * input_dir.y + cam_right * input_dir.x).normalized()
	
	## Плавный поворот в сторону движения
	#if move_dir.length() > 0.1:
		#var target_yaw = atan2(move_dir.x, move_dir.z)
		#rotation.y = lerp_angle(rotation.y, target_yaw, delta * 15.0)
		
	var target_yaw = deg_to_rad(camera_yaw)
	rotation.y = lerp_angle(rotation.y, target_yaw, delta * 15.0)
	
	if input_dir != Vector2.ZERO:
		#print("move_dir: ", move_dir, " input_dir: ", input_dir)
		pass
		

	
	Network.send_input(move_dir.x, move_dir.z)
	
	print_timer += delta
	if print_timer > 0.5:
		#print("rotation.y=", rotation.y, " last_sent=", last_sent_rotation)
		print_timer = 0.0
	
	
	rotation_sync_timer += delta
	if rotation_sync_timer > 0.1:
		rotation_sync_timer = 0.0
		if abs(rotation.y - last_sent_rotation) > 0.01:
			last_sent_rotation = rotation.y
			Network.send_rotation(rotation.y)

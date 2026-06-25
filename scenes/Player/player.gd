extends CharacterBody3D


@onready var camera_3d: Camera3D = $Camera3D
@onready var metarig: Node3D = $metarig

const SPEED = 10.0
const JUMP_VELOCITY = 4.5

var sensitivity: float = 0.2
var is_attacking: bool = false


var camera_pitch: float = 0.0
var camera_distance: float = 3.0
var camera_height: float = 2.0
var is_first_person: bool = false

var old_event = null


func _camera_update():
		if is_first_person:
			metarig.visible = false
			
			camera_3d.global_position = global_position + Vector3(0, 1.5, 0)
			camera_3d.rotation = Vector3(deg_to_rad(-camera_pitch), 0, 0)  # ← ЭТО
		else:
			metarig.visible = true
			
			var angle_rad = deg_to_rad(camera_pitch)
			var backward = transform.basis.z * camera_distance * cos(angle_rad)
			var up = Vector3.UP * (camera_height + camera_distance * sin(angle_rad))
			camera_3d.global_position = global_position + backward + up
			camera_3d.look_at(global_position + Vector3(0, 1.5, 0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sensitivity))
		print("поворот")
		print(rotation.y)
		
		camera_pitch += event.relative.y * sensitivity
		
		camera_pitch = clamp(camera_pitch, -90.0, 45.0)
		_camera_update()
		
		
		
		
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_view"):
		is_first_person = !is_first_person
		_camera_update()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_attacking:
				is_attacking = true
			$AnimationPlayer.stop()
			$AnimationPlayer.play("ShoveTwoHands")
			await $AnimationPlayer.animation_finished
			$AnimationPlayer.play("Idle")
			is_attacking = false
			
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
		

func _physics_process(_delta: float) -> void:
	# Если атакуем — не трогаем анимацию
	if is_attacking:
		return
		
	var input_dir = Input.get_vector("leftA", "rightD", "upW", "downS")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		$AnimationPlayer.play("Run")
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		$AnimationPlayer.play("Idle")
	
	move_and_slide()

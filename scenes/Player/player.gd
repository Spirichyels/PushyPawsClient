extends CharacterBody3D

func _ready():
	Network.set_local_player(self)

func _physics_process(delta):
	if not Network.connected or Network.my_id == -1:
		return
	
	var input_dir = Input.get_vector("leftA", "rightD", "upW", "downS")
	Network.send_input(input_dir.x, input_dir.y, rotation.y)

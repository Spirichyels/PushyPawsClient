extends Node

var ws = WebSocketPeer.new()
var connected = false
var my_id = -1
var players = {}
var local_player = null

@onready var player_scene = preload("res://scenes/Player/player.tscn")

func _ready():
	var url = "ws://127.0.0.1:8000/ws"
	var err = ws.connect_to_url(url)
	if err == OK:
		print("Подключение...")
	else:
		print("Ошибка: ", err)

func _process(delta):
	ws.poll()
	
	match ws.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not connected:
				connected = true
				print("✅ Подключено к серверу!")
			
			while ws.get_available_packet_count() > 0:
				var packet = ws.get_packet()
				var data = packet.get_string_from_utf8()
				var parsed = JSON.parse_string(data)
				
				if parsed == null:
					continue
				
				if connected and my_id == -1:
					ws.send_text(JSON.stringify({"type": "get_id"}))
				
				match str(parsed.get("type")):
					"state":
						_update_players(parsed["players"])
					"assign_id":
						my_id = parsed["id"]
						print("🆔 Мой ID: ", my_id)
		
		WebSocketPeer.STATE_CLOSED:
			if connected:
				connected = false
				print("❌ Соединение закрыто")

func send_input(move_x: float, move_z: float, rot: float = 0.0):
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN and my_id != -1:
		var msg = {
			"type": "input",
			"move": [move_x, move_z],
			"rot": rot
		}
		ws.send_text(JSON.stringify(msg))

func _update_players(players_data):
	for pid in players_data:
		var pos_data = players_data[pid]["pos"]
		var pos = Vector3(pos_data[0], pos_data[1], pos_data[2])
		var rot = players_data[pid].get("rot", 0.0)
		
		if int(pid) == my_id:
			if local_player:
				local_player.global_position = pos
				local_player.rotation.y = rot
		else:
			if not players.has(pid):
				var new_player = player_scene.instantiate()
				get_tree().current_scene.add_child(new_player)
				players[pid] = {
					"node": new_player,
					"pos": pos,
					"rot": rot
				}
			else:
				players[pid]["node"].global_position = pos
				players[pid]["node"].rotation.y = rot

func set_local_player(player_node):
	local_player = player_node

extends Node

var ws = WebSocketPeer.new()
var connected = false
var my_id = -1
var players = {}
var local_player = null
var my_uid = ""

var window_id = "default"

@onready var id_label: Label3D = $IdLabel


@onready var player_scene = preload("res://scenes/Player/player.tscn")
@onready var test_table = preload("res://scenes/GUI/TestTable/test_table.tscn")

var test_table_init

func _start_test_table(uid, id, window):
	test_table_init = test_table.instantiate()
	get_tree().current_scene.add_child(test_table_init)
	test_table_init.uid = uid
	test_table_init.id = id
	test_table_init.window = window
	

func _ready():
	# это для тестов в 2 окнах
	var args = OS.get_cmdline_args()
	for i in range(args.size()):
		if args[i] == "--window-id" and i + 1 < args.size():
			window_id = args[i + 1]
			break
	print("🪟 Window ID: ", window_id)
	
	
	# Читаем сохранённый UID
	var file_path = "user://player_uid_" + window_id + ".txt"
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		my_uid = file.get_as_text().strip_edges()
		file.close()
		print("📂 Найден UID: ", my_uid)
	
	
	if ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		ws.close()
		await get_tree().process_frame
	ws = WebSocketPeer.new()
		
	var url = "ws://127.0.0.1:8000/ws"
	if ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
		ws.close()
	ws = WebSocketPeer.new()
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
				# Отправляем restore или пустое сообщение
				if my_uid != "":
					var restore_msg = {
						"type": "restore",
						"uid": my_uid
					}
					ws.send_text(JSON.stringify(restore_msg))
					print("📤 Отправлен restore с UID: ", my_uid)
				else:
					# Нет UID — просто шлём что-то, чтобы сервер создал нового
					ws.send_text(JSON.stringify({"type": "new"}))
					print("📤 Запрос нового игрока")
			
			while ws.get_available_packet_count() > 0:
				var packet = ws.get_packet()
				var data = packet.get_string_from_utf8()
				var parsed = JSON.parse_string(data)
				if parsed == null:
					continue
				match str(parsed.get("type")):
					"state":
						_update_players(parsed["players"], delta)
					"assign_id":
						my_id = parsed["id"]
						my_uid = parsed.get("uid", "")
						print("🆔 Мой ID: ", my_id, " | UID: ", my_uid)
						
						# Сохраняем новый UID в файл
						var file_path = "user://player_uid_" + window_id + ".txt"
						var file = FileAccess.open(file_path, FileAccess.WRITE)
						if file:
							file.store_string(my_uid)
							file.close()
							print("💾 UID сохранён: ", my_uid)
						
						# Удаляем всех чужих игроков (создались с my_id=-1)
						for pid in players.keys():
							if players[pid]["node"] != null:
								players[pid]["node"].queue_free()
						players.clear()
						
						# Удаляем старую таблицу если была
						if test_table_init != null:
							test_table_init.queue_free()
							test_table_init = null
						
						# Создаём своего игрока
						if local_player == null:
							local_player = player_scene.instantiate()
							get_tree().current_scene.add_child(local_player)
							local_player.set_id_label(my_id)
							print("🎮 Свой игрок создан с ID:", my_id)
							_start_test_table(my_uid, my_id, window_id)
							# Запрашиваем текущее состояние у сервера
							ws.send_text(JSON.stringify({"type": "request_state"}))
							
						
		WebSocketPeer.STATE_CLOSED:
			if connected:
				connected = false
				print("❌ Соединение закрыто")

@warning_ignore("unused_parameter")
func send_input(move_x: float, move_z: float, rot: float = 0.0):
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN and my_id != -1:
		var move_msg = {
			"type": "move",
			"x": move_x,
			"z": move_z
		}
		ws.send_text(JSON.stringify(move_msg))
		
		#var rot_msg = {
			#"type": "rotate",
			#"yaw": rot
		#}
		#ws.send_text(JSON.stringify(rot_msg))

@warning_ignore("unused_parameter")
func _update_players(players_data, delta):
	for pid in players_data:
		var pos_data = players_data[pid]["pos"]
		var pos = Vector3(pos_data[0], pos_data[1], pos_data[2])
		var rot = players_data[pid].get("rot", 0.0)
		var int_pid = int(pid)
		
		if int_pid == my_id:
			if local_player:
				local_player.global_position = pos
		else:
			if not players.has(pid):
				var new_player = player_scene.instantiate()
				get_tree().current_scene.add_child(new_player)
				new_player.set_id_label(int_pid)
				players[pid] = {
					"node": new_player,
					"pos": pos,
					"rot": rot
				}
			else:
				if players[pid]["pos"].distance_to(pos) > 0.01:
					players[pid]["node"].global_position = pos
					players[pid]["pos"] = pos
				if abs(players[pid]["rot"] - rot) > 0.01:
					#players[pid]["node"].rotation.y = lerp_angle(players[pid]["node"].rotation.y, rot, delta * 15.0)
					players[pid]["node"].rotation.y = rot
					players[pid]["rot"] = rot
					pass
				pass
		
func set_local_player(player_node):
	local_player = player_node
	
	
func send_attack(rot: float):
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN and my_id != -1:
		var msg = {
			"type": "attack",
			"yaw": rot
		}
		ws.send_text(JSON.stringify(msg))

func send_rotation(rot: float):
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN and my_id != -1:
		var msg = {
			"type": "rotate",
			"yaw": rot
		}
		ws.send_text(JSON.stringify(msg))

func send_jump():
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN and my_id != -1:
		var msg = {"type": "jump"}
		print("Отправляю jump")
		ws.send_text(JSON.stringify(msg))
	else:
		print("ws не открыт или my_id=-1")

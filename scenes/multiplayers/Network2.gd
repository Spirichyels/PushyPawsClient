extends Node

var ws = WebSocketPeer.new()
var connected = false

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
			
			# Читаем входящие сообщения
			while ws.get_available_packet_count() > 0:
				var packet = ws.get_packet()
				var data = packet.get_string_from_utf8()
				var parsed = JSON.parse_string(data)
				
				if parsed and parsed["type"] == "state":
					print("📦 Получено игроков: ", parsed["players"].size())
					for player_id in parsed["players"]:
						var pos_data = parsed["players"][player_id]["pos"]
						var pos = Vector3(pos_data[0], pos_data[1], pos_data[2])
						print("Игрок", player_id, " в ", pos)
		
		WebSocketPeer.STATE_CLOSED:
			if connected:
				connected = false
				print("❌ Соединение закрыто")

func send_position(pos: Vector3):
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var msg = {
			"type": "update",
			"pos": [pos.x, pos.y, pos.z]
		}
		ws.send_text(JSON.stringify(msg))
		
func send_input(move_x: float, move_z: float):
	if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var msg = {
			"type": "input",
			"move": [move_x, move_z]
		}
		ws.send_text(JSON.stringify(msg))

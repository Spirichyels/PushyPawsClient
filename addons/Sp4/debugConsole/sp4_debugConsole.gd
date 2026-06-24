extends CanvasLayer
const CLOSSED_CONSOLE_INPUT_TEXT = "toggle_console"
const version = 3
@onready var console_labels: VBoxContainer = %VBC
var _array_console = []

func _ready() -> void:
	
	#ОТКРЫТИЕ КОНСОЛИ НА (`+SHIFT)
	# Добавляем действие, если его ещё нет
	if not InputMap.has_action(CLOSSED_CONSOLE_INPUT_TEXT):
		# Создаём новое действие
		InputMap.add_action(CLOSSED_CONSOLE_INPUT_TEXT)
		
		# Создаём событие клавиши `
		var event = InputEventKey.new()
		event.keycode = KEY_QUOTELEFT
		event.shift_pressed = true  # Добавляем Shift
		
		# Привязываем событие к действию
		InputMap.action_add_event(CLOSSED_CONSOLE_INPUT_TEXT, event)
	pass 


func sp4_print(new_text):
	var x = Label.new()
	x.text = str(new_text)
	console_labels.add_child(x)
	_array_console.push_front(x)
	if _array_console.size() >= 200:
		sp4_minus_label_console()
	
func sp4_minus_label_console():
	var x = _array_console.pop_front()
	if x != null:
		x.queue_free()
		pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_console"):
		visible = !visible


func _on_clear_button_pressed() -> void:
	for label in _array_console:
		if is_instance_valid(label) and label != null:
			label.queue_free()  # Безопасное удаление
	_array_console.clear()
	pass # Replace with function body.


func _on_add_test_label_pressed() -> void:
	sp4_print("Тест")
	pass # Replace with function body.

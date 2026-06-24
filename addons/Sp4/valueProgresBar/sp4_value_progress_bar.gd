@tool  # <-- ВАЖНО
extends ProgressBar
class_name sp4_ValueProgressBar

@export var show_value: bool = true:
	set(value):
		show_value = value
		update_configuration_warnings()
		queue_redraw()

@export var value_format: String = "%d/%d":
	set(value):
		value_format = value
		queue_redraw()


func current_hp_changed(new_hp):
	value = new_hp
func max_hp_changed(new_hp):
	max_value = new_hp


func _ready():
	show_percentage = false

func _draw():
	if not show_value:
		return
		
	var text = value_format % [value, max_value]
	var font = get_theme_font("font")
	var font_size = get_theme_font_size("font_size")
		
	# Получаем метрики шрифта
	var ascent = font.get_ascent(font_size)     # высота над базовой линией
	var descent = font.get_descent(font_size)   # высота под базовой линией
	var total_height = ascent + descent
		
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_x = (size.x - text_size.x) / 2
		
	# Центрируем по реальной высоте шрифта
	var text_y = (size.y - total_height) / 2 + ascent
		
	draw_string(font, Vector2(text_x, text_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)# Принудительно обновляем при изменении свойств
func _property_changed(property: String):
	if property in ["value", "max_value", "show_value", "value_format"]:
		queue_redraw()

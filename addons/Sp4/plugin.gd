@tool
extends EditorPlugin

func _enter_tree():
	# Регистрируем наш тип
	add_custom_type("sp4_ValueProgressBar", "ProgressBar", preload("valueProgresBar/sp4_value_progress_bar.gd"), null)
	

func _exit_tree():
	# Убираем регистрацию
	remove_custom_type("sp4_ValueProgressBar")
	
	

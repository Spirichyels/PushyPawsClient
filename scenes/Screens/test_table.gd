extends CanvasLayer


@onready var uid_label: Label = $VBC/UidLabel
@onready var id_label: Label = $VBC/IdLabel
@onready var window_label: Label = $VBC/WindowLabel


var id = -1:
	set(value):
		id = value
		if id_label != null:
			id_label.text = str(id)
		else:
			id_label.text = "null"

var uid = -1:
	set(value):
		uid = value
		if uid_label != null:
			uid_label.text = str(uid)
		else:
			uid_label.text = "nulld"


var window = -1:
	set(value):
		window = value
		if window_label != null:
			window_label.text = str(window)
		else:
			window_label.text = "nulld"

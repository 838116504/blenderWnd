tool
extends TextureButton

signal mouse_in
signal mouse_out
signal close

var isMouseIn = false

func _init():
	connect("toggled", self, "_on_titleBar_toggled")
	connect("mouse_entered", self, "_on_titleBar_mouse_entered")
	connect("mouse_exited", self, "_on_titleBar_mouse_exited")

#func get_text_label():
#	return $textLabel

func _get_minimum_size():
	var iconNode = get_icon_btn()
	if iconNode:
		return iconNode.get_minimum_size() + Vector2(2.0, 0.0)
	else:
		return Vector2.ZERO


func get_icon_btn():
	return $iconBtn

func get_close_btn():
	return $closeBtn

#func _on_iconBtn_item_selected(p_index):
#	get_text_label().text = get_icon_btn().get_item_text(p_index)
#
#
#func _on_iconBtn_item_focused(p_index):
#	get_text_label().text = get_icon_btn().get_item_text(p_index)


func _on_titleBar_toggled(p_buttonPressed):
	if p_buttonPressed:
		get_icon_btn().disabled = false
		get_icon_btn().mouse_filter = Control.MOUSE_FILTER_STOP
	else:
		get_icon_btn().disabled = true
		get_icon_btn().mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_titleBar_mouse_entered():
	if !isMouseIn:
		isMouseIn = true
		emit_signal("mouse_in")

func _on_titleBar_mouse_exited():
	if isMouseIn && !Rect2(Vector2.ZERO, rect_size).has_point(get_local_mouse_position()):
		isMouseIn = false
		emit_signal("mouse_out")

func _on_closeBtn_mouse_entered():
	_on_titleBar_mouse_entered()


func _on_closeBtn_mouse_exited():
	_on_titleBar_mouse_exited()


func _on_iconBtn_mouse_entered():
	_on_titleBar_mouse_entered()


func _on_iconBtn_mouse_exited():
	_on_titleBar_mouse_exited()


func _on_closeBtn_pressed():
	emit_signal("close")

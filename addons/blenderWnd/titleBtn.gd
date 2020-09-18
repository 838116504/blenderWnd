tool
extends "res://addons/easyButton/easyButton.gd"

signal mouse_in
signal mouse_out
signal close

var isNormalDefault := true
var isPressedDefault := true
var isHoverDefault := true
var isMenuPanelDefault := true
var isMenuFontDefault := true
var isMouseIn = false


func _init():
	connect("toggled", self, "_on_titleBtn_toggled")
	connect("mouse_entered", self, "_on_titleBtn_mouse_entered")
	connect("mouse_exited", self, "_on_titleBtn_mouse_exited")


func _get_minimum_size():
	var iconNode = get_icon_btn()
	if iconNode:
		var closeBtnMin = get_close_btn().get_minimum_size()
		var iconNodeMin = iconNode.get_minimum_size()
		return Vector2(max(closeBtnMin.x, iconNodeMin.x), max(closeBtnMin.y, iconNodeMin.y)) + Vector2(2.0, 0.0)
	else:
		print("[titleBtn] Didnt find icon button!")
		return get_close_btn().get_minimum_size() + Vector2(2.0, 0.0)

func _notification(what):
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			var closeBtn = get_close_btn()
			closeBtn.texture_normal = get_icon("title_close", "BlenderWnd") if has_icon("title_close", "BlenderWnd") else preload("closeIcon.png")
			if closeBtn.texture_normal:
				closeBtn.margin_left = -get_close_btn().texture_normal.get_size().x
				closeBtn.margin_top = -get_close_btn().texture_normal.get_size().y / 2.0
				closeBtn.margin_bottom = -get_close_btn().margin_top
			
			
			closeBtn.texture_hover = get_icon("title_close_hover", "BlenderWnd") if has_icon("title_close_hover", "BlenderWnd") else preload("closeIcon_hover.png")
			if closeBtn.texture_hover:
				closeBtn.margin_left = -get_close_btn().texture_hover.get_size().x
				closeBtn.margin_top = -get_close_btn().texture_hover.get_size().y / 2.0
				closeBtn.margin_bottom = -get_close_btn().margin_top
			
			closeBtn.texture_pressed = get_icon("title_close_pressed", "BlenderWnd") if has_icon("title_close_pressed", "BlenderWnd") else null
			if closeBtn.texture_pressed:
				closeBtn.margin_left = -get_close_btn().texture_pressed.get_size().x
				closeBtn.margin_top = -get_close_btn().texture_pressed.get_size().y / 2.0
				closeBtn.margin_bottom = -get_close_btn().margin_top
			
			rect_min_size = _get_minimum_size()
			if not get_icon_btn().is_connected("item_selected", self, "_on_iconBtn_item_selected"):
				get_icon_btn().connect("item_selected", self, "_on_iconBtn_item_selected")
			if not get_icon_btn().get_popup().is_connected("about_to_show", self, "_on_iconBtn_popup_show"):
				get_icon_btn().get_popup().connect("about_to_show", self, "_on_iconBtn_popup_show")
		NOTIFICATION_MOVED_IN_PARENT:
			_on_titleBtn_mouse_exited()

func _on_iconBtn_item_selected(p_index):
	rect_min_size = _get_minimum_size()

func _on_iconBtn_popup_show():
	if isMouseIn:
		isMouseIn = false
		emit_signal("mouse_out")

func get_class():
	return "BlenderWnd"

func get_icon_btn():
	return $iconBtn

func get_close_btn():
	return $closeBtn


func _on_titleBtn_toggled(p_buttonPressed):
	if p_buttonPressed:
		get_icon_btn().disabled = false
		get_icon_btn().mouse_filter = Control.MOUSE_FILTER_PASS
	else:
		get_icon_btn().disabled = true
		get_icon_btn().mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_titleBtn_mouse_entered():
	if !isMouseIn:
		isMouseIn = true
		emit_signal("mouse_in")

func _on_titleBtn_mouse_exited():
	if isMouseIn && !Rect2(Vector2.ZERO, rect_size).has_point(get_local_mouse_position()):
		isMouseIn = false
		emit_signal("mouse_out")

func _on_closeBtn_mouse_entered():
	_on_titleBtn_mouse_entered()


func _on_closeBtn_mouse_exited():
	_on_titleBtn_mouse_exited()


func _on_iconBtn_mouse_entered():
	_on_titleBtn_mouse_entered()


func _on_iconBtn_mouse_exited():
	_on_titleBtn_mouse_exited()


func _on_closeBtn_pressed():
	emit_signal("close")

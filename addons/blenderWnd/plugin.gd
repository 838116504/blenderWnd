tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("BlenderWnd", "Control", preload("res://addons/blenderWnd/blenderWnd.gd"), get_editor_interface().get_base_control().get_icon("PopupPanel", "EditorIcons"))


func _exit_tree():
	remove_custom_type("BlenderWnd")

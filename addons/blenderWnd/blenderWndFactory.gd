tool
class_name BlenderWndFactory
extends Resource


func create_wnd() -> Node:
	return Control.new()

func get_icon() -> Texture:
	return null

func get_title() -> String:
	return "empty"

func get_minimum_size() -> Vector2:
	return Vector2(0.0, 0.0)

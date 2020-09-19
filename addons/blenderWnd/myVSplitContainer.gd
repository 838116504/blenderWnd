tool
extends VSplitContainer

const DEFAULT_SEPARATION = 2
const DEFAULT_GRABBER = preload("empty.png")
const DEFAULT_BG = preload("empty_styleboxempty.tres")

func _init():
	connect("dragged", self, "_on_self_dragged")

static func get_class_static():
	return "BlenderWnd"

func _notification(what):
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			var sep = get_constant("split_v_separation") if has_constant("split_v_separation") else DEFAULT_SEPARATION
			if sep != get_constant("separation"):
				add_constant_override("separation", sep)
			var grabber = get_icon("split_v_grabber") if has_icon("split_v_grabber") else DEFAULT_GRABBER
			if grabber != get_icon("grabber"):
				add_icon_override("grabber", grabber)
			var bg = get_stylebox("split_v_bg") if has_stylebox("split_v_bg") else DEFAULT_BG
			if bg != get_stylebox("bg"):
				add_stylebox_override("bg", bg)

func _on_self_dragged(p_offset):
	set_offset_with_mouse_pos()


func set_offset_with_mouse_pos():
	set_offset(get_global_mouse_position().y - rect_global_position.y)

func set_offset(p_offset):
	split_offset = 0
	if get_child_count() < 2:
		return
	var sep = float(get_constant("separation"))
	var size = get_global_rect().size - Vector2(sep, sep)
	var offset = clamp(p_offset, get_child(0).get_combined_minimum_size().y, size.y - get_child(1).get_combined_minimum_size().y)
	
	var first = get_child(0)
	if first is VSplitContainer:
		offset -= offset_fix(first, 1, offset - first.size_flags_stretch_ratio * size.y)
	var second = get_child(1)
	if second is VSplitContainer:
		offset += offset_fix(second, 0, size.y - second.size_flags_stretch_ratio * size.y - offset)
	
	var ratio = offset / size.y
	first.size_flags_stretch_ratio = ratio
	second.size_flags_stretch_ratio = 1.0 - ratio

# return unuse offset
func offset_fix(p_container:VSplitContainer, p_childId:int, p_offset:float):
	if p_container.get_child_count() < 2:
		return 0.0
	
	var fixChild = p_container.get_child(p_childId)
	while fixChild is VSplitContainer && fixChild.get_child_count() >= 2:
		fixChild = fixChild.get_child(p_childId)
	
	var p = fixChild.get_parent()
	var pSep = float(p.get_constant("separation"))
	var pSize = p.get_global_rect().size - Vector2(pSep, pSep)
	var chSHeight = fixChild.size_flags_stretch_ratio * pSize.y
	var chHeight = max(fixChild.get_combined_minimum_size().y, chSHeight + p_offset)
	var offset = chHeight - chSHeight
	pSize.y += offset
	fixChild.size_flags_stretch_ratio = chHeight / pSize.y
	var nextChildId = 0 if p_childId == 1 else 1
	p.get_child(nextChildId).size_flags_stretch_ratio = 1.0 - fixChild.size_flags_stretch_ratio
	
	while p != p_container:
		fixChild = p
		p = fixChild.get_parent()
		pSep = float(p.get_constant("separation"))
		pSize = p.get_global_rect().size - Vector2(pSep, pSep)
		var h = fixChild.size_flags_stretch_ratio * pSize.y + offset
		pSize.y += offset
		fixChild.size_flags_stretch_ratio = h / pSize.y
		p.get_child(nextChildId).size_flags_stretch_ratio = 1.0 - fixChild.size_flags_stretch_ratio
	
	return p_offset - offset
	


func has_constant(p_name:String, p_type:String = "") -> bool:
	if p_type == "" && not has_constant_override(p_name) && p_name == "split_v_separation":
		p_type = get_class_static()
	return .has_constant(p_name, p_type)

func has_icon(p_name:String, p_type:String = "") -> bool:
	if p_type == "" && not has_icon_override(p_name) && p_name == "split_v_grabber":
		p_type = get_class_static()
	return .has_icon(p_name, p_type)

func has_stylebox(p_name:String, p_type:String = "") -> bool:
	if p_type == "" && not has_stylebox_override(p_name) && p_name == "split_v_bg":
		p_type = get_class_static()
	return .has_stylebox(p_name, p_type)

func get_constant(p_name:String, p_type:String = ""):
	if p_type == "" && not has_constant_override(p_name) && p_name == "split_v_separation":
		p_type = get_class_static()
	return .get_constant(p_name, p_type)

func get_icon(p_name:String, p_type:String = ""):
	if p_type == "" && not has_icon_override(p_name) && p_name == "split_v_grabber":
		p_type = get_class_static()
	return .get_icon(p_name, p_type)


func get_stylebox(p_name:String, p_type:String = ""):
	if p_type == "" && not has_stylebox_override(p_name) && p_name == "split_v_bg":
		p_type = get_class_static()
	return .get_stylebox(p_name, p_type)

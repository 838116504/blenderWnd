extends HSplitContainer

func _init():
	connect("dragged", self, "_on_self_dragged")


func _on_self_dragged(p_offset):
	set_offset_with_mouse_pos()



func set_offset_with_mouse_pos():
	set_offset(get_global_mouse_position().x - rect_global_position.x)

# p_offset: local split pos
func set_offset(p_offset:float):
	split_offset = 0
	if get_child_count() < 2:
		return
	var sep = float(get_constant("separation"))
	var size = get_global_rect().size - Vector2(sep, sep)
	p_offset -= sep / 2.0
	var offset = clamp(p_offset, get_child(0).get_combined_minimum_size().x, size.x - get_child(1).get_combined_minimum_size().x)
	
	var first = get_child(0)
	if first is HSplitContainer:
		offset -= offset_fix(first, 1, offset - first.size_flags_stretch_ratio * size.x)
	var second = get_child(1)
	if second is HSplitContainer:
		offset += offset_fix(second, 0, size.x - second.size_flags_stretch_ratio * size.x - offset)
	
	var ratio = offset / size.x
	first.size_flags_stretch_ratio = ratio
	second.size_flags_stretch_ratio = 1.0 - ratio

# return unuse offset
func offset_fix(p_container:HSplitContainer, p_childId:int, p_offset:float):
	if p_container.get_child_count() < 2:
		return 0.0
	
	var fixChild = p_container.get_child(p_childId)
	while fixChild is HSplitContainer && fixChild.get_child_count() >= 2:
		fixChild = fixChild.get_child(p_childId)
	
	var p = fixChild.get_parent()
	var pSep = float(p.get_constant("separation"))
	var pSize = p.get_global_rect().size - Vector2(pSep, pSep)
	var chSWidth = fixChild.size_flags_stretch_ratio * pSize.x
	var chWidth = max(fixChild.get_combined_minimum_size().x, chSWidth + p_offset)
	var offset = chWidth - chSWidth
	pSize.x += offset
	fixChild.size_flags_stretch_ratio = chWidth / pSize.x
	var nextChildId = 0 if p_childId == 1 else 1
	p.get_child(nextChildId).size_flags_stretch_ratio = 1.0 - fixChild.size_flags_stretch_ratio
	
	while p != p_container:
		fixChild = p
		p = fixChild.get_parent()
		pSep = float(p.get_constant("separation"))
		pSize = p.get_global_rect().size - Vector2(pSep, pSep)
		var w = fixChild.size_flags_stretch_ratio * pSize.x + offset
		pSize.x += offset
		fixChild.size_flags_stretch_ratio = w / pSize.x
		p.get_child(nextChildId).size_flags_stretch_ratio = 1.0 - fixChild.size_flags_stretch_ratio
	
	return p_offset - offset
	

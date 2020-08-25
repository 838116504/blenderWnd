tool
extends Control

export var defaultShowTitleBar := false
export var showTitleBar := false setget set_show_title_bar
export(Array, GDScript) var childWndFactoryGd = [] setget set_child_wnd_factory_gd
export var defaultWndFactoryId := 0
export var margin:float = 10.0

var childWnds := [ null ]
#var wndsClassId := [ -1 ]
var childWndFactoryPaths := [ null ]
var currentChildWndId := -1 setget set_current_child_wnd_id
var childWndFactories := [] setget set_child_wnd_factories

var wndTitleSC := ScrollContainer.new()
var wndTitleHBC := HBoxContainer.new()
var leftArrowTBtn := TextureButton.new()
var rightArrowTBtn := TextureButton.new()
var topHBC = HBoxContainer.new()
var wndControl := Control.new()
var wndVBC := VBoxContainer.new()

var titleBarBtnGroup = ButtonGroup.new()

var dragPos : Vector2
enum { DRAG_NONE = -1, DRAG_ON_EDGE = 0, DRAG_SPLIT_LEFT, DRAG_SPLIT_RIGHT, DRAG_SPLIT_TOP, DRAG_SPLIT_BOTTOM, 
		DRAG_DELETE_LEFT, DRAG_DELETE_RIGHT, DRAG_DELETE_TOP, DRAG_DELETE_BOTTOM, 
		DRAG_DELETE_SELF_LEFT,  DRAG_DELETE_SELF_RIGHT, DRAG_DELETE_SELF_TOP, DRAG_DELETE_SELF_BOTTOM }
enum { DIR_LEFT = 0, DIR_RIGHT, DIR_UP, DIR_DOWN }
var dragState:int = DRAG_NONE

const MyHSplitContainer = preload("myHSplitContainer.gd")
const MyVSplitContainer = preload("myVSplitContainer.gd")

var deleteArrowTex = [ preload("leftArrow.png"), preload("upArrow.png") ]

func _init():
	rect_clip_content = false
	focus_mode = Control.FOCUS_ALL
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	
#	var wndVBC = VBoxContainer.new()
	wndVBC.size_flags_horizontal = SIZE_EXPAND_FILL
	wndVBC.size_flags_vertical = SIZE_EXPAND_FILL
	wndVBC.anchor_right = ANCHOR_END
	wndVBC.anchor_bottom = ANCHOR_END
#	wndVBC.margin_left = margin
#	wndVBC.margin_right = -margin
#	wndVBC.margin_top = margin
#	wndVBC.margin_bottom = -margin
	wndVBC.margin_right = 0
	wndVBC.margin_bottom = 0
	wndVBC.add_constant_override("separation", 0)
	
	# top
#	var topHBC = HBoxContainer.new()
	topHBC.size_flags_horizontal = SIZE_EXPAND_FILL
	topHBC.add_constant_override("separation", 0)
	if not showTitleBar:
		topHBC.hide()
	
	
#	wndTitleSC = ScrollContainer.new()
	wndTitleSC.scroll_vertical_enabled = false
	wndTitleSC.get_h_scrollbar().hide()
	wndTitleSC.get_h_scrollbar().connect("changed", self, "_on_wndTitleSC_h_scrollbar_changed")
#	wndTitleHBC = HBoxContainer.new()
	wndTitleHBC.size_flags_horizontal = SIZE_EXPAND_FILL
	wndTitleHBC.add_constant_override("separation", 2)
	for i in childWnds.size():
		var node = create_title_node()
		wndTitleHBC.add_child(node)
		set_child_wnd_class(i, -1)
	var addBtn = TextureButton.new()
	addBtn.texture_normal = preload("addIcon.png")
	addBtn.connect("pressed", self, "_on_addWndBtn_pressed")
	wndTitleHBC.add_child(addBtn)
	
#	leftArrowTBtn = TextureButton.new()
	leftArrowTBtn.texture_normal = get_icon("GuiScrollArrowLeft", "EditorIcons")
	leftArrowTBtn.texture_hover = get_icon("GuiScrollArrowLeftHl", "EditorIcons")
	leftArrowTBtn.expand = true
	leftArrowTBtn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	leftArrowTBtn.rect_min_size = Vector2(16.0, 16.0)
	
#	rightArrowTBtn = TextureButton.new()
	rightArrowTBtn.texture_normal = get_icon("GuiScrollArrowRight", "EditorIcons")
	rightArrowTBtn.texture_hover = get_icon("GuiScrollArrowRightHl", "EditorIcons")
	rightArrowTBtn.expand = true
	rightArrowTBtn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	rightArrowTBtn.rect_min_size = Vector2(16.0, 16.0)
	
	wndTitleSC.size_flags_horizontal = SIZE_EXPAND_FILL
#	wndTitleSC.rect_min_size = Vector2(96.0, 32.0)
	topHBC.add_child(wndTitleSC)
	topHBC.add_child(leftArrowTBtn)
	topHBC.add_child(rightArrowTBtn)
	wndTitleSC.add_child(wndTitleHBC)
	
	
	# window
#	wndControl = Control.new()
	wndControl.rect_clip_content = true
	wndControl.size_flags_vertical = SIZE_EXPAND_FILL
	
	wndVBC.add_child(topHBC)
	wndVBC.add_child(wndControl)
#	wndVBC.rect_min_size = Vector2(128.0, 128.0)
	
	add_child(wndVBC)
	set_current_child_wnd_id(0)
	
	var btn = Control.new()
	btn.mouse_default_cursor_shape = Control.CURSOR_CROSS
	btn.mouse_filter = Control.MOUSE_FILTER_PASS
	btn.margin_right = margin
	btn.margin_bottom = margin
	add_child(btn)
	btn = btn.duplicate()
	btn.anchor_left = ANCHOR_END
	btn.anchor_right = ANCHOR_END
	btn.margin_left = -margin
	btn.margin_right = 0.0
	add_child(btn)
	btn = btn.duplicate()
	btn.anchor_top = ANCHOR_END
	btn.anchor_bottom = ANCHOR_END
	btn.margin_top = -margin
	btn.margin_bottom = 0.0
	add_child(btn)
	btn = btn.duplicate()
	btn.anchor_left = ANCHOR_BEGIN
	btn.anchor_right = ANCHOR_BEGIN
	btn.margin_left = 0.0
	btn.margin_right = margin
	add_child(btn)

func _get_minimum_size():
	var wndMinSize = Vector2.ZERO
	var temp
	for i in childWndFactories:
		temp = i.get_minimum_size()
		wndMinSize = Vector2(max(temp.x, wndMinSize.x), max(temp.y, wndMinSize.y))
	var titleMinSize = topHBC.get_minimum_size()
	
	wndMinSize.y += titleMinSize.y
	wndMinSize.x = max(titleMinSize.x, wndMinSize.x)
	return wndMinSize

func _process(p_delta):
	if leftArrowTBtn && leftArrowTBtn.get_draw_mode() == BaseButton.DRAW_HOVER_PRESSED:
		wndTitleSC.scroll_horizontal -= 1.0
	elif rightArrowTBtn && rightArrowTBtn.get_draw_mode() == BaseButton.DRAW_HOVER_PRESSED:
		wndTitleSC.scroll_horizontal += 1.0
	if wndTitleSC.get_child(0).get_minimum_size().x <= topHBC.rect_size.x:
		leftArrowTBtn.hide()
		rightArrowTBtn.hide()
	else:
		leftArrowTBtn.show()
		rightArrowTBtn.show()

func _input(p_event):
	if p_event is InputEventKey && get_global_rect().has_point(get_global_mouse_position()):
		if p_event.pressed && not p_event.echo && p_event.scancode == KEY_TAB && not p_event.alt && not p_event.control && not p_event.shift:
			set_show_title_bar(!showTitleBar)
	if dragState <= DRAG_ON_EDGE:
		return
	
	if p_event is InputEventMouseButton:
		if p_event.button_index == BUTTON_LEFT:
			if p_event.pressed:
				unuse_custom_cursor()
				dragState = DRAG_NONE
			else:
				get_tree().set_input_as_handled()
				match dragState:
					DRAG_DELETE_LEFT, DRAG_DELETE_RIGHT, DRAG_DELETE_TOP, DRAG_DELETE_BOTTOM:
						var arrowNode = get_delete_arrow()
						if arrowNode:
							remove_child(arrowNode.get_parent())
							var delWnd = arrowNode.get_meta("delWnd")
							arrowNode.queue_free()
							remove_wnd(delWnd)
					DRAG_DELETE_SELF_LEFT, DRAG_DELETE_SELF_RIGHT, DRAG_DELETE_SELF_TOP, DRAG_DELETE_SELF_BOTTOM:
						remove_wnd(self)
				unuse_custom_cursor()
				dragState = DRAG_NONE
	elif p_event is InputEventMouseMotion:
		if is_using_custom_cursor():
			get_child(0).get_child(0).position = get_global_mouse_position()
		
		if !Input.is_mouse_button_pressed(BUTTON_LEFT):
			print("[blenderWnd::_input] Mouse left button not pressed when drag!")
			match dragState:
				DRAG_DELETE_LEFT, DRAG_DELETE_RIGHT, DRAG_DELETE_TOP, DRAG_DELETE_BOTTOM:
					var arrowNode = get_delete_arrow()
					if arrowNode:
						remove_child(arrowNode.get_parent())
						var delWnd = arrowNode.get_meta("delWnd")
						arrowNode.queue_free()
						remove_wnd(delWnd)
				DRAG_DELETE_SELF_LEFT, DRAG_DELETE_SELF_RIGHT, DRAG_DELETE_SELF_TOP, DRAG_DELETE_SELF_BOTTOM:
					remove_wnd(self)
			unuse_custom_cursor()
			dragState = DRAG_NONE
			return
		
		match dragState:
			DRAG_SPLIT_LEFT, DRAG_SPLIT_RIGHT:
#				get_parent().split_offset = get_global_mouse_position().x - get_parent().rect_global_position.x - get_parent().get_child(0).rect_min_size.x
#				get_parent().clamp_split_offset()
#				var p = get_parent()
#				var sep = float(p.get_constant("separation")) / 2.0
#				var pSize = p.get_global_rect().size
#				var offset = clamp(get_global_mouse_position().x - p.rect_global_position.x, p.get_child(0).get_combined_minimum_size().x + sep, pSize.x - p.get_child(1).get_combined_minimum_size().x - sep)
#				p.get_child(0).set_ratio(offset / pSize.x)
				get_parent().set_offset_with_mouse_pos()
			DRAG_SPLIT_TOP, DRAG_SPLIT_BOTTOM:
#				get_parent().split_offset = get_global_mouse_position().y - get_parent().rect_global_position.y - get_parent().get_child(0).rect_min_size.y
#				get_parent().clamp_split_offset()
#				var p = get_parent()
#				var sep = float(p.get_constant("separation")) / 2.0
#				var pSize = p.get_global_rect().size
#				var offset = clamp(get_global_mouse_position().y - p.rect_global_position.y, p.get_child(0).get_combined_minimum_size().y + sep, pSize.y - p.get_child(1).get_combined_minimum_size().y - sep)
#				p.get_child(0).set_ratio(offset / pSize.y)
				get_parent().set_offset_with_mouse_pos()
			DRAG_DELETE_LEFT:
				if get_global_mouse_position().x - rect_global_position.x > 0.0:
					dragState = DRAG_DELETE_SELF_LEFT
					var arrowNode = get_delete_arrow()
					arrowNode.rect_position = rect_global_position
					arrowNode.rect_size = get_global_rect().size
					arrowNode.flip_h = true
			DRAG_DELETE_SELF_LEFT:
				if get_global_mouse_position().x - rect_global_position.x < 0.0:
					dragState = DRAG_DELETE_LEFT
					var arrowNode = get_delete_arrow()
					var delWnd = arrowNode.get_meta("delWnd")
					arrowNode.rect_position = delWnd.rect_global_position
					arrowNode.rect_size = delWnd.get_global_rect().size
					arrowNode.flip_h = false
			DRAG_DELETE_RIGHT:
				if get_global_mouse_position().x < get_global_rect().end.x:
					dragState = DRAG_DELETE_SELF_RIGHT
					var arrowNode = get_delete_arrow()
					arrowNode.rect_position = rect_global_position
					arrowNode.rect_size = get_global_rect().size
					arrowNode.flip_h = false
			DRAG_DELETE_SELF_RIGHT:
				if get_global_mouse_position().x > get_global_rect().end.x:
					dragState = DRAG_DELETE_RIGHT
					var arrowNode = get_delete_arrow()
					var delWnd = arrowNode.get_meta("delWnd")
					arrowNode.rect_position = delWnd.rect_global_position
					arrowNode.rect_size = delWnd.get_global_rect().size
					arrowNode.flip_h = true
			DRAG_DELETE_TOP:
				if get_global_mouse_position().y - rect_global_position.y > 0.0:
					dragState = DRAG_DELETE_SELF_TOP
					var arrowNode = get_delete_arrow()
					arrowNode.rect_position = rect_global_position
					arrowNode.rect_size = get_global_rect().size
					arrowNode.flip_v = true
			DRAG_DELETE_SELF_TOP:
				if get_global_mouse_position().y - rect_global_position.y < 0.0:
					dragState = DRAG_DELETE_TOP
					var arrowNode = get_delete_arrow()
					var delWnd = arrowNode.get_meta("delWnd")
					arrowNode.rect_position = delWnd.rect_global_position
					arrowNode.rect_size = delWnd.get_global_rect().size
					arrowNode.flip_v = false
			DRAG_DELETE_BOTTOM:
				if get_global_mouse_position().y < get_global_rect().end.y:
					dragState = DRAG_DELETE_SELF_BOTTOM
					var arrowNode = get_delete_arrow()
					arrowNode.rect_position = rect_global_position
					arrowNode.rect_size = get_global_rect().size
					arrowNode.flip_v = false
			DRAG_DELETE_SELF_BOTTOM:
				if get_global_mouse_position().y > get_global_rect().end.y:
					dragState = DRAG_DELETE_BOTTOM
					var arrowNode = get_delete_arrow()
					var delWnd = arrowNode.get_meta("delWnd")
					arrowNode.rect_position = delWnd.rect_global_position
					arrowNode.rect_size = delWnd.get_global_rect().size
					arrowNode.flip_v = true
		
		get_tree().set_input_as_handled()

func _gui_input(p_event):
	if p_event is InputEventMouseButton:
		if p_event.button_index == BUTTON_LEFT:
			if p_event.pressed:
				if dragState < 0 && (p_event.position.x < margin || p_event.position.x > rect_size.x - margin) && \
						(p_event.position.y < margin || p_event.position.y > rect_size.y - margin):
					dragPos = p_event.position
					dragState = DRAG_ON_EDGE
			elif dragState == DRAG_ON_EDGE:
				unuse_custom_cursor()
				dragState = DRAG_NONE
			elif dragState != DRAG_NONE:
				print("[blenderWnd::_gui_input] dragState should be DRAG_NONE, but is ", str(dragState))
				unuse_custom_cursor()
				dragState = DRAG_NONE
	elif p_event is InputEventMouseMotion && dragState >= DRAG_ON_EDGE:
		match dragState:
			DRAG_ON_EDGE:
				dragState = get_next_state(p_event.position)
				
				match dragState:
					DRAG_DELETE_LEFT, DRAG_DELETE_RIGHT, DRAG_DELETE_TOP, DRAG_DELETE_BOTTOM:
						var delWnd = find_delete_wnd(dragState - DRAG_DELETE_LEFT)
						
						if delWnd == null:
							dragState = DRAG_ON_EDGE
							use_custom_cursor(preload("banCursor.png"))
						else:
							add_delete_arrow(dragState - DRAG_DELETE_LEFT, delWnd)
							if dragState == DRAG_DELETE_LEFT:
								use_custom_cursor(preload("mergeCursorRight.png"), true)
							elif dragState == DRAG_DELETE_RIGHT:
								use_custom_cursor(preload("mergeCursorRight.png"))
							elif dragState == DRAG_DELETE_TOP:
								use_custom_cursor(preload("mergeCursorUp.png"))
							else:
								use_custom_cursor(preload("mergeCursorUp.png"), false, true)
					DRAG_SPLIT_LEFT, DRAG_SPLIT_RIGHT, DRAG_SPLIT_TOP, DRAG_SPLIT_BOTTOM:
						if ((dragState == DRAG_SPLIT_LEFT || dragState == DRAG_SPLIT_RIGHT) && rect_size.x <= get_minimum_size().x * 2.0) || \
								((dragState == DRAG_SPLIT_TOP || dragState == DRAG_SPLIT_BOTTOM) && rect_size.y <= get_minimum_size().y * 2.0):
							dragState = DRAG_ON_EDGE
							use_custom_cursor(preload("banCursor.png"))
						else:
							split(dragState - DRAG_SPLIT_LEFT)
							if dragState == DRAG_SPLIT_LEFT || dragState == DRAG_SPLIT_RIGHT:
								use_custom_cursor(preload("hSplitCursor.png"))
							else:
								use_custom_cursor(preload("vSplitCursor.png"))
			_:
				dragState = DRAG_NONE
				print("[blenderWnd::_gui_input] dragState is not DRAG_ON_EDGE")

func is_using_custom_cursor():
	return get_child(0) is CanvasLayer

func use_custom_cursor(p_cursorImg:Texture, p_flipH := false, p_flipV := false):
	if !is_using_custom_cursor():
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		var layer = CanvasLayer.new()
		layer.layer = 0xFFFFFF
		var cursorTex = Sprite.new()
		layer.add_child(cursorTex)
		cursorTex.position = get_global_mouse_position()
		add_child(layer)
		move_child(layer, 0)
	var sprite = get_child(0).get_child(0)
	sprite.texture = p_cursorImg
	sprite.flip_h = p_flipH
	sprite.flip_v = p_flipV

func unuse_custom_cursor():
	if is_using_custom_cursor():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		var layer = get_child(0)
		remove_child(layer)
		layer.queue_free()

func get_next_state(p_localMousePos:Vector2):
	if dragState != DRAG_ON_EDGE:
		return dragState
	
	var vec = p_localMousePos - dragPos
	if vec.length() < 3.0:
		return DRAG_ON_EDGE
	
	if abs(vec.x) >= abs(vec.y):
		if vec.x > 0:
			if dragPos.x <= margin:
				return DRAG_SPLIT_LEFT
			else:
				return DRAG_DELETE_RIGHT
		else:
			if dragPos.x <= margin:
				return DRAG_DELETE_LEFT
			else:
				return DRAG_SPLIT_RIGHT
	else:
		if vec.y > 0:
			if dragPos.y <= margin:
				return DRAG_SPLIT_TOP
			else:
				return DRAG_DELETE_BOTTOM
		else:
			if dragPos.y <= margin:
				return DRAG_DELETE_TOP
			else:
				return DRAG_SPLIT_BOTTOM
#	if Rect2(Vector2.ZERO, rect_size).has_point(p_localMousePos):
#		if (p_localMousePos.x < margin || p_localMousePos.x > rect_size.x - margin) && \
#				(p_localMousePos.y < margin || p_localMousePos.y > rect_size.y - margin):
#			return DRAG_ON_EDGE
#		else:
#			var vec =  p_localMousePos - dragPos
#			if abs(vec.x) >= abs(vec.y):
#				if dragPos.x <= margin:
#					return DRAG_SPLIT_LEFT
#				else:
#					return DRAG_SPLIT_RIGHT
#			else:
#				if dragPos.y <= margin:
#					return DRAG_SPLIT_TOP
#				else:
#					return DRAG_SPLIT_BOTTOM
#	else:
#		if p_localMousePos.x < 0.0:
#			if p_localMousePos.y < margin:
#				var vec = p_localMousePos - dragPos
#				if abs(vec.x) > abs(vec.y):
#					return DRAG_DELETE_LEFT
#				else:
#					return DRAG_DELETE_TOP
#			elif p_localMousePos.y >= rect_size.y - margin:
#				var vec = p_localMousePos - dragPos
#				if abs(vec.x) > abs(vec.y):
#					return DRAG_DELETE_LEFT
#				else:
#					return DRAG_DELETE_BOTTOM
#			else:
#				return DRAG_DELETE_LEFT
#		elif p_localMousePos.x > rect_size.x:
#			if p_localMousePos.y < 0.0:
#				var vec = p_localMousePos - dragPos
#				if abs(vec.x) > abs(vec.y):
#					return DRAG_DELETE_RIGHT
#				else:
#					return DRAG_DELETE_TOP
#			elif p_localMousePos.y >= rect_size.y - margin:
#				var vec = p_localMousePos - dragPos
#				if abs(vec.x) > abs(vec.y):
#					return DRAG_DELETE_RIGHT
#				else:
#					return DRAG_DELETE_BOTTOM
#			else:
#				return DRAG_DELETE_RIGHT
#		elif p_localMousePos.y < 0.0:
#			return DRAG_DELETE_TOP
#		else:
#			return DRAG_DELETE_BOTTOM

func add_delete_arrow(p_dir, p_deleteWnd:Control):
	var texRect := TextureRect.new()
	texRect.rect_size = p_deleteWnd.get_global_rect().size
	texRect.stretch_mode = TextureRect.STRETCH_SCALE
	texRect.expand = true
	texRect.rect_position = p_deleteWnd.rect_global_position
	match p_dir:
		DIR_LEFT:
			texRect.texture = deleteArrowTex[0]
		DIR_RIGHT:
			texRect.texture = deleteArrowTex[0]
			texRect.flip_h = true
		DIR_UP:
			texRect.texture = deleteArrowTex[1]
		DIR_DOWN:
			texRect.texture = deleteArrowTex[1]
			texRect.flip_v = true
	
	texRect.set_meta("delWnd", p_deleteWnd)
	var layer = CanvasLayer.new()
	layer.layer = 0xFFFFFF - 1
	layer.add_child(texRect)
	add_child(layer)

func get_delete_arrow():
	var node = get_child(get_child_count() - 1)
	if not node is CanvasLayer:
		return null
	
	return node.get_child(0)

func split(p_dir:int):
	if p_dir < 0 || p_dir > 3:
		return
	
	var id = get_index()
	var p = get_parent()
	p.remove_child(self)
	
	var sc:SplitContainer
	if p_dir == DIR_LEFT || p_dir == DIR_RIGHT:
		sc = MyHSplitContainer.new()
	else:
		sc = MyVSplitContainer.new()
	
	sc.anchor_right = ANCHOR_END
	sc.anchor_bottom = ANCHOR_END
	sc.margin_right = 0.0
	sc.margin_bottom = 0.0
	sc.size_flags_horizontal = self.size_flags_horizontal
	sc.size_flags_vertical = self.size_flags_vertical
	sc.size_flags_stretch_ratio = size_flags_stretch_ratio
	self.size_flags_horizontal = SIZE_EXPAND_FILL
	self.size_flags_vertical = SIZE_EXPAND_FILL
	size_flags_stretch_ratio = 0.5
	sc.theme = theme
	sc.split_offset = 0
	if not p is Container:
		sc.anchor_left = anchor_left
		sc.anchor_right = anchor_right
		sc.anchor_bottom = anchor_bottom
		sc.anchor_top = anchor_top
		
		sc.margin_left = margin_left
		sc.margin_right = margin_right
		sc.margin_bottom = margin_bottom
		sc.margin_top = margin_top
	else:
		sc.rect_size = rect_size

	var newWnd = new_wnd()
	if p_dir == DIR_LEFT || p_dir == DIR_UP:
		sc.add_child(newWnd)
		sc.add_child(self)
	else:
		sc.add_child(self)
		sc.add_child(newWnd)
	
	p.add_child(sc)
	p.move_child(sc, id)
	
	if p_dir == DIR_LEFT || p_dir == DIR_RIGHT:
		sc.split_offset = get_global_mouse_position().x - sc.rect_global_position.x - sc.get_child(0).rect_min_size.x
	else:
		sc.split_offset = get_global_mouse_position().y - sc.rect_global_position.y - sc.get_child(0).rect_min_size.y
	sc.clamp_split_offset()


func new_wnd():
	var newWnd = get_script().new()
	newWnd.childWndFactories = childWndFactories
	newWnd.margin = margin
	newWnd.theme = theme
	newWnd.defaultShowTitleBar = defaultShowTitleBar
	newWnd.showTitleBar = newWnd.defaultShowTitleBar
	newWnd.defaultWndFactoryId = defaultWndFactoryId
	newWnd.set_child_wnd_class(0, -1)
	newWnd.set_ratio(size_flags_stretch_ratio)
	return newWnd

func set_ratio(p_ratio):
	size_flags_stretch_ratio = p_ratio
	if get_parent() is SplitContainer:
		for i in get_parent().get_children():
			if i == self:
				continue
			i.size_flags_stretch_ratio = 1.0 - p_ratio

func remove_wnd(p_wnd):
	var p = p_wnd.get_parent()
	var gp = p.get_parent()
	var id = p.get_index()
	var nextId = 0 if id == 1 else 1
	var node = gp
	while not node.is_a_parent_of(self):
		node = node.get_parent()
	if node == gp:
		nextId = id
	var offset
	var needFix = node is SplitContainer && p_wnd.get_parent() != get_parent() && p_wnd != self
	if needFix:
		if p is HSplitContainer:
			offset = p_wnd.get_global_rect().size.x
		else:
			offset = p_wnd.get_global_rect().size.y
	gp.remove_child(p)

	var children = p.get_children()
	children.invert()
	for i in children:
		if i == p_wnd:
			continue
		p.remove_child(i)
		gp.add_child(i)
		gp.move_child(i, id)
		i.size_flags_horizontal = p.size_flags_horizontal
		i.size_flags_vertical = p.size_flags_vertical
		i.size_flags_stretch_ratio = p.size_flags_stretch_ratio
		if not gp is Container:
			i.anchor_left = p.anchor_left
			i.anchor_right = p.anchor_right
			i.anchor_bottom = p.anchor_bottom
			i.anchor_top = p.anchor_top
			
			i.margin_left = p.margin_left
			i.margin_right = p.margin_right
			i.margin_bottom = p.margin_bottom
			i.margin_top = p.margin_top
	
	if needFix:
		var sep = float(node.get_constant("separation"))
		if node is HSplitContainer:
			var pW = node.get_global_rect().size.x
			var chW = node.get_child(nextId).size_flags_stretch_ratio * (pW - sep) - offset
			if nextId == 0:
				node.set_offset(chW + sep / 2.0)
			else:
				node.set_offset(pW - chW - sep / 2.0)
		else:
			var pH = node.get_global_rect().size.y
			var chH = node.get_child(nextId).size_flags_stretch_ratio * (pH - sep) - offset
			if nextId == 0:
				node.set_offset(chH + sep / 2.0)
			else:
				node.set_offset(pH - chH - sep / 2.0)
		
	p.queue_free()

func find_delete_wnd(p_dir:int):
	var find
	var findClass
	var selfId
	match p_dir:
		DIR_LEFT:
			findClass = HSplitContainer
			selfId = 1
		DIR_RIGHT:
			findClass = HSplitContainer
			selfId = 0
		DIR_UP:
			findClass = VSplitContainer
			selfId = 1
		DIR_DOWN:
			findClass = VSplitContainer
			selfId = 0
	
	find = find_parent_by_class(findClass)
	while find != null && find.get_child(selfId) != self && not find.get_child(selfId).is_a_parent_of(self):
		find = find_parent_by_class(findClass, find)
	if find == null:
		return null
	
	var findId = 0 if selfId == 1 else 1
	find = find.get_child(findId)
	if not find is findClass:
		return find

	findId = 0 if findId == 1 else 1
	
	while find is findClass:
		find = find.get_child(findId)
	
	return find


func find_parent_by_class(p_class, p_node = self):
	var parent = p_node.get_parent()
	while parent != null && not parent is p_class:
		parent = parent.get_parent()
	
	return parent

func set_show_title_bar(p_value:bool):
	if p_value == showTitleBar:
		return
	showTitleBar = p_value
	if showTitleBar:
		topHBC.show()
	else:
		topHBC.hide()

func create_title_node():
	var ret = preload("titleBtn.tscn").instance()
	ret.group = titleBarBtnGroup
	ret.connect("mouse_in", self, "_on_titleBar_mouse_in", [ret])
	ret.connect("mouse_out", self, "_on_titleBar_mouse_out", [ret])
	ret.connect("close", self, "_on_titleBar_close", [ret])
	var iconNode = ret.get_icon_btn()
	for i in childWndFactories.size():
		iconNode.add_icon_item(childWndFactories[i].get_icon(), childWndFactories[i].get_title(), i)
	ret.connect("pressed", self, "_on_titleBar_pressed", [ret])
	return ret

func set_child_wnd_class(p_wndId, p_factoryId:int):
	if p_factoryId >= 0 && childWndFactoryPaths[p_wndId] == childWndFactories[p_factoryId].get_script().get_path():
		var iconNode = wndTitleHBC.get_child(p_wndId).get_icon_btn()
		if iconNode.get_selected_id() != p_factoryId:
			iconNode.select(p_factoryId)
		return
	
	if p_factoryId < 0:
		if defaultWndFactoryId >= 0 && defaultWndFactoryId < childWndFactories.size():
			p_factoryId = defaultWndFactoryId
			if childWndFactoryPaths[p_wndId] == childWndFactories[p_factoryId].get_script().get_path():
				var iconNode = wndTitleHBC.get_child(p_wndId).get_icon_btn()
				if iconNode.get_selected_id() != p_factoryId:
					iconNode.select(p_factoryId)
				return
		elif childWndFactoryPaths[p_wndId] == null:
			return
	
	if childWnds[p_wndId]:
		childWnds[p_wndId].queue_free()
	
	
	var titleNode = wndTitleHBC.get_child(p_wndId)
	
	if p_factoryId >= 0:
		childWnds[p_wndId] = childWndFactories[p_factoryId].create_wnd()
		childWndFactoryPaths[p_wndId] = childWndFactories[p_factoryId].get_script().get_path()
		titleNode.get_icon_btn().select(p_factoryId)
	else:
		childWnds[p_wndId] = null
		childWndFactoryPaths[p_wndId] = null
		titleNode.get_icon_btn().select(-1)
	

	if childWnds[p_wndId] != null && currentChildWndId == p_wndId:
		wndControl.add_child(childWnds[p_wndId])

func set_current_child_wnd_id(p_value:int):
	if p_value == currentChildWndId:
		return
	
	currentChildWndId = p_value
	for i in wndControl.get_children():
		wndControl.remove_child(i)
	
	
	if currentChildWndId >= 0:
		wndTitleHBC.get_child(currentChildWndId).pressed = true
		if childWnds[currentChildWndId] != null:
			wndControl.add_child(childWnds[currentChildWndId])

func add_child_wnd(p_factoryId, p_wnd = null, p_pos := -1):
	if p_factoryId < 0 && defaultWndFactoryId >= 0 && defaultWndFactoryId < childWndFactories.size():
		p_factoryId = defaultWndFactoryId
	if p_wnd == null:
		if p_factoryId >= 0:
			p_wnd = childWndFactories[p_factoryId].create_wnd()
	
	var titleNode = create_title_node()
	titleNode.get_icon_btn().select(p_factoryId)
	
	wndTitleHBC.add_child(titleNode)
	
	if p_pos < 0:
		wndTitleHBC.move_child(titleNode, childWnds.size())
		childWnds.append(p_wnd)
		if p_factoryId >= 0:
			childWndFactoryPaths.append(childWndFactories[p_factoryId].get_script().get_path())
		else:
			childWndFactoryPaths.append(null)
	else:
		wndTitleHBC.move_child(titleNode, p_pos)
		childWnds.insert(p_pos, p_wnd)
		if p_factoryId >= 0:
			childWndFactoryPaths.insert(p_pos, childWndFactories[p_factoryId].get_script().get_path())
		else:
			childWndFactoryPaths.insert(p_pos, null)
		if currentChildWndId >= p_pos:
			currentChildWndId += 1
	
	if currentChildWndId < 0:
		if p_pos >= 0:
			set_current_child_wnd_id(p_pos)
		else:
			set_current_child_wnd_id(childWnds.size() - 1)

func remove_child_wnd(p_pos:int):
	if currentChildWndId == p_pos:
		if childWnds.size() > 1:
			set_current_child_wnd_id(p_pos - 1 if p_pos > 0 else p_pos + 1)
		else:
			set_current_child_wnd_id(-1)
	var titleNode = wndTitleHBC.get_child(p_pos)
	wndTitleHBC.remove_child(titleNode)
	childWnds.remove(p_pos)
	childWndFactoryPaths.remove(p_pos)

	titleNode.queue_free()

func _on_addWndBtn_pressed():
	add_child_wnd(-1)

func _on_titleBar_pressed(p_titleBar):
	set_current_child_wnd_id(p_titleBar.get_index())

func _on_titleBar_mouse_in(p_titleBar):
	if childWnds.size() > 1:
		p_titleBar.get_close_btn().show()

func _on_titleBar_mouse_out(p_titleBar):
	p_titleBar.get_close_btn().hide()

func _on_titleBar_close(p_titleBar):
	if childWnds.size() < 2:
		return
	
	remove_child_wnd(p_titleBar.get_index())

func _on_wndTitleSC_h_scrollbar_changed():
	var hSB = wndTitleSC.get_h_scrollbar()
	if hSB.value == hSB.max_value:
		rightArrowTBtn.disabled = true
	else:
		rightArrowTBtn.disabled = false
	if hSB.value == hSB.min_value:
		leftArrowTBtn.disabled = true
	else:
		leftArrowTBtn.disabled = false

func update_child_wnd_class():
	var prevMinSize = rect_min_size
	rect_min_size = get_minimum_size()
	if rect_min_size != prevMinSize:
		self.minimum_size_changed()
	
	for i in childWnds.size():
		var iconNode = wndTitleHBC.get_child(i).get_icon_btn()
		iconNode.clear()
		for j in childWndFactories.size():
			iconNode.add_icon_item(childWndFactories[j].get_icon(), childWndFactories[j].get_title(), j)
	
	for i in childWnds.size():
		if childWndFactoryPaths[i] != null:
			var find = false
			for j in childWndFactories.size():
				if childWndFactories[j].get_script().get_path() == childWndFactoryPaths[i]:
					set_child_wnd_class(i, j)
					find = true
					break
			if !find:
				set_child_wnd_class(i, -1)
		else:
			set_child_wnd_class(i, -1)

func set_child_wnd_factory_gd(p_value):
	childWndFactoryGd = p_value
	var objs = []
	objs.resize(childWndFactoryGd.size())
	for i in childWndFactoryGd.size():
		objs[i] = childWndFactoryGd[i].new()
	
	set_child_wnd_factories(objs)

func set_child_wnd_factories(p_value:Array):
	childWndFactories = p_value
	update_child_wnd_class()

func add_child_wnd_factory(p_factory):
	childWndFactories.append(p_factory)
	update_child_wnd_class()

func add_child_wnd_factories(p_factories:Array):
	for i in p_factories:
		childWndFactories.append(i)
	update_child_wnd_class()

func save_layout(p_savePath:String):
	pass

func get_layout_data():
	return

func load_layout(p_loadPath:String):
	pass

func set_layout_data(p_data):
	pass

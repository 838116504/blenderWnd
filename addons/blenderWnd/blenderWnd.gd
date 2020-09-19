tool
#class_name BlenderWnd
extends Control

enum { DRAG_NONE = -1, DRAG_ON_EDGE, DRAG_BAN, DRAG_SPLIT_LEFT, DRAG_SPLIT_RIGHT, DRAG_SPLIT_TOP, DRAG_SPLIT_BOTTOM,
		DRAG_MERGE_LEFT, DRAG_MERGE_RIGHT, DRAG_MERGE_TOP, DRAG_MERGE_BOTTOM, 
		DRAG_MERGE_SELF_LEFT,  DRAG_MERGE_SELF_RIGHT, DRAG_MERGE_SELF_TOP, DRAG_MERGE_SELF_BOTTOM, DRAG_NUM }
enum { DIR_LEFT = 0, DIR_RIGHT, DIR_UP, DIR_DOWN }

const ScrollBoxContainer = preload("res://addons/scrollBoxContainer/scrollBoxContainer.gd")
const TransitionAnimation = preload("res://addons/transitionAnimation/transitionAnimation.gd")
const MyHSplitContainer = preload("myHSplitContainer.gd")
const MyVSplitContainer = preload("myVSplitContainer.gd")
const EasyButton = preload("res://addons/easyButton/easyButton.gd")
const SelectEffect = preload("selectEffect.gd")
const HoverEffect = preload("hoverEffect.gd")
const TitleBtn = preload("titleBtn.gd")
const CONSTANT_THEME_NAMES = { "split_h_separation":4, "split_v_separation":4 }
const ICON_THEME_NAMES = { "cursor_ban":preload("banCursor.png"), "cursor_merge_bottom":preload("mergeCursorDown.png"), "cursor_merge_left":preload("mergeCursorLeft.png"), 
		"cursor_merge_right":preload("mergeCursorRight.png"), "cursor_merge_top":preload("mergeCursorUp.png"), "cursor_split_h":preload("hSplitCursor.png"), "cursor_split_v":preload("vSplitCursor.png"),
		"split_h_grabber":preload("empty.png"), "split_v_grabber":preload("empty.png"), "title_close":preload("closeIcon.png"), 
		"title_close_hover":preload("closeIcon_hover.png"), "title_close_pressed":null }
const FONT_THEME_NAMES = { "title_font":null, "title_menu_font":null }
const STYLEBOX_THEME_NAMES = { "split_h_bg":null, "split_v_bg":null, "title_add_hover":preload("empty_styleboxempty.tres"), "title_add_normal":preload("addBtn_normal_styleboxtexture.tres"), 
		"title_add_pressed":preload("empty_styleboxempty.tres"), "title_bg_hover":preload("empty_styleboxempty.tres"), "title_bg_normal":preload("titleBtn_normal_styleboxtexture.tres"),
		"title_bg_pressed":preload("titleBtn_pressed_styleboxtexture.tres"), "title_menu_bg":null }
const DRAG_STATE_THEME_NAME = { DRAG_BAN:"cursor_ban", DRAG_SPLIT_LEFT:"cursor_split_h", DRAG_SPLIT_RIGHT:"cursor_split_h", DRAG_SPLIT_TOP:"cursor_split_v", DRAG_SPLIT_BOTTOM:"cursor_split_v", 
		DRAG_MERGE_LEFT:"cursor_merge_left", DRAG_MERGE_RIGHT:"cursor_merge_right", DRAG_MERGE_TOP:"cursor_merge_top", DRAG_MERGE_BOTTOM:"cursor_merge_bottom", 
		DRAG_MERGE_SELF_LEFT:"cursor_merge_left",  DRAG_MERGE_SELF_RIGHT:"cursor_merge_right", DRAG_MERGE_SELF_TOP:"cursor_merge_top", DRAG_MERGE_SELF_BOTTOM:"cursor_merge_bottom" }
const mergeArrowTex = [ preload("mergeLeft.svg"), preload("mergeUp.svg") ]
const CLASS_NAME = "BlenderWnd"
enum { THEME_GROUP = 0, THEME_CONSTANT, THEME_ICON, THEME_STYLEBOX, THEME_FONT }
const THEME_METHODS = [ "_property_add_group", "_property_add_constant", "_property_add_icon", "_property_add_stylebox", "_property_add_font" ]
const THEMES = [
		THEME_GROUP, "Cursor", 
		THEME_ICON, "cursor_ban",
		THEME_ICON, "cursor_split_h",
		THEME_ICON, "cursor_split_v",
		THEME_ICON, "cursor_merge_bottom",
		THEME_ICON, "cursor_merge_left",
		THEME_ICON, "cursor_merge_right",
		THEME_ICON, "cursor_merge_top",
		
		THEME_GROUP, "Split",
		THEME_STYLEBOX, "split_h_bg",
		THEME_ICON, "split_h_grabber",
		THEME_CONSTANT, "split_h_separation",
		THEME_STYLEBOX, "split_v_bg",
		THEME_ICON, "split_v_grabber",
		THEME_CONSTANT, "split_v_separation", 
		
		THEME_GROUP, "Title",
		THEME_STYLEBOX, "title_add_normal",
		THEME_STYLEBOX, "title_add_hover",
		THEME_STYLEBOX, "title_add_pressed",
		THEME_STYLEBOX, "title_bg_normal",
		THEME_STYLEBOX, "title_bg_hover",
		THEME_STYLEBOX, "title_bg_pressed",
		THEME_ICON, "title_close",
		THEME_ICON, "title_close_hover",
		THEME_ICON, "title_close_pressed",
		THEME_STYLEBOX, "title_menu_bg",
		THEME_FONT, "title_menu_font",
		THEME_FONT, "title_font"
		]


signal child_wnd_closed
signal child_wnd_created
signal child_wnd_toggled
signal layout_changed


export var defaultShowTitleBar := false
export var defaultWndFactoryId := 0
export var showTitleBar := false setget set_show_title_bar
export var drag_margin:float = 10.0 setget set_drag_margin
export var currentChildWndId:int = -1 setget set_current_child_wnd_id


var titleBar := ScrollBoxContainer.new()
var titleBarTranAnim := TransitionAnimation.new()
var wndControl := Control.new()
var wndVBC := VBoxContainer.new()
var addWndBtn := EasyButton.new()
var leftTopControl:Control
var rightTopControl:Control
var rightBottomControl:Control
var leftBottomControl:Control
var dragRegionEffects = []
var dragHoverEffect

var titleBarBtnGroup = ButtonGroup.new()
var childWnds := [ ]
var wndFactories := [] setget set_wnd_factories
var dragPos : Vector2
var dragState:int = DRAG_NONE setget set_drag_state, get_drag_state
var isDragingTitle := false

static func get_class_static() -> String:
	return CLASS_NAME

func get_parent_class():
	return Control

static func get_parent_class_static():
	return Control

func _init():
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	
	wndVBC.size_flags_horizontal = SIZE_EXPAND_FILL
	wndVBC.size_flags_vertical = SIZE_EXPAND_FILL
	wndVBC.set_anchors_and_margins_preset(Control.PRESET_WIDE)
	wndVBC.add_constant_override("separation", 0)
	add_child(wndVBC)
	
	titleBar.set_anchors_and_margins_preset(Control.PRESET_TOP_WIDE)

	addWndBtn.connect("pressed", self, "_on_addWndBtn_pressed")
	addWndBtn.size_flags_vertical = SIZE_SHRINK_CENTER
	addWndBtn.add_font_override("font", DynamicFont.new())
	titleBar.add_child(addWndBtn)
	titleBar.connect("resized", self, "_on_titleBar_resized")

	wndVBC.add_child(titleBarTranAnim)
	titleBarTranAnim.size_flags_horizontal = SIZE_EXPAND_FILL
	titleBarTranAnim.useChildMinSize = true
	titleBarTranAnim.add_child(titleBar)
	titleBarTranAnim.gradient = AccGradient.new()
	titleBarTranAnim.animTime = 0.8
	titleBarTranAnim.rect_clip_content = true
	if not showTitleBar:
		titleBarTranAnim.hide_without_anim()
	
	wndControl.rect_clip_content = true
	wndControl.size_flags_vertical = SIZE_EXPAND_FILL
	wndVBC.add_child(wndControl)
	
	
	leftTopControl = Control.new()
	leftTopControl.mouse_default_cursor_shape = Control.CURSOR_CROSS
	leftTopControl.mouse_filter = Control.MOUSE_FILTER_PASS
	leftTopControl.margin_right = drag_margin
	if showTitleBar:
		leftTopControl.margin_top = titleBar.rect_size.y
		leftTopControl.margin_bottom = drag_margin + leftTopControl.margin_top
	else:
		leftTopControl.margin_bottom = drag_margin
	add_child(leftTopControl)
	rightTopControl = leftTopControl.duplicate()
	rightTopControl.anchor_left = ANCHOR_END
	rightTopControl.anchor_right = ANCHOR_END
	rightTopControl.margin_left = -drag_margin
	rightTopControl.margin_right = 0.0
	add_child(rightTopControl)
	rightBottomControl = rightTopControl.duplicate()
	rightBottomControl.anchor_top = ANCHOR_END
	rightBottomControl.anchor_bottom = ANCHOR_END
	rightBottomControl.margin_top = -drag_margin
	rightBottomControl.margin_bottom = 0.0
	add_child(rightBottomControl)
	leftBottomControl = rightBottomControl.duplicate()
	leftBottomControl.anchor_left = ANCHOR_BEGIN
	leftBottomControl.anchor_right = ANCHOR_BEGIN
	leftBottomControl.margin_left = 0.0
	leftBottomControl.margin_right = drag_margin
	add_child(leftBottomControl)

func _ready():
	_empty_check()
	_current_child_wnd_check()

func _get_minimum_size():
	var wndMinSize = Vector2.ZERO
	var temp
	for i in wndFactories:
		if i == null || not i is BlenderWndFactory:
			continue
		temp = i.get_minimum_size()
		wndMinSize = Vector2(max(temp.x, wndMinSize.x), max(temp.y, wndMinSize.y))
	var titleMinSize = titleBarTranAnim.get_combined_minimum_size()
	
	wndMinSize.y += titleMinSize.y
	wndMinSize.x = max(titleMinSize.x, wndMinSize.x)
	return wndMinSize

func _empty_check():
	if not is_inside_tree() || not visible || wndFactories.size() <= 0 || childWnds.size() > 0:
		return
	
	var defaultFactory = _get_default_factory()
	if wndFactories[defaultFactory] == null || not wndFactories[defaultFactory] is BlenderWndFactory:
		return
	
	new_child_wnd()

func _current_child_wnd_check():
	if not is_inside_tree():
		return
	
	if childWnds.size() <= 0:
		currentChildWndId = -1
		return
	elif currentChildWndId < 0:
		currentChildWndId = 0
	elif currentChildWndId >= childWnds.size():
		currentChildWndId = childWnds.size() - 1
	
	if childWnds[currentChildWndId] != null:
		childWnds[currentChildWndId].show()
	titleBar.get_child(currentChildWndId).pressed = true

func get_add_child_wnd_button() -> EasyButton:
	return addWndBtn

func _notification(what):
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			if titleBar.theme == null:
				titleBar.theme = Theme.new()
			var addButton = get_add_child_wnd_button()
			if has_stylebox("title_add_hover"):
				addButton.add_stylebox_override("hover", get_stylebox("title_add_hover"))
			else:
				addButton.add_stylebox_override("hover", STYLEBOX_THEME_NAMES["title_add_hover"])
			if has_stylebox("title_add_normal"):
				addButton.add_stylebox_override("normal", get_stylebox("title_add_normal"))
			else:
				addButton.add_stylebox_override("normal", STYLEBOX_THEME_NAMES["title_add_normal"])
			if has_stylebox("title_add_pressed"):
				addButton.add_stylebox_override("pressed", get_stylebox("title_add_pressed"))
			else:
				addButton.add_stylebox_override("pressed", STYLEBOX_THEME_NAMES["title_add_pressed"])
			
			
			if has_stylebox("title_bg_hover"):
				titleBar.theme.set_stylebox("hover", "Button", get_stylebox("title_bg_hover"))
			else:
				titleBar.theme.set_stylebox("hover", "Button", STYLEBOX_THEME_NAMES["title_bg_hover"])
			if has_stylebox("title_bg_normal"):
				titleBar.theme.set_stylebox("normal", "Button", get_stylebox("title_bg_normal"))
			else:
				titleBar.theme.set_stylebox("normal", "Button", STYLEBOX_THEME_NAMES["title_bg_normal"])
			if has_stylebox("title_bg_pressed"):
				titleBar.theme.set_stylebox("pressed", "Button", get_stylebox("title_bg_pressed"))
			else:
				titleBar.theme.set_stylebox("pressed", "Button", STYLEBOX_THEME_NAMES["title_bg_pressed"])
			
			if has_icon_override("title_close"):
				titleBar.theme.set_icon("title_close", get_class_static(), get_icon("title_close"))
			elif titleBar.theme.has_icon("title_close", get_class_static()):
				titleBar.theme.clear_icon("title_close", get_class_static())
			if has_icon_override("title_close_hover"):
				titleBar.theme.set_icon("title_close_hover", get_class_static(), get_icon("title_close_hover"))
			elif titleBar.theme.has_icon("title_close_hover", get_class_static()):
				titleBar.theme.clear_icon("title_close_hover", get_class_static())
			if has_icon_override("title_close_pressed"):
				titleBar.theme.set_icon("title_close_pressed", get_class_static(), get_icon("title_close_pressed"))
			elif titleBar.theme.has_icon("title_close_pressed", get_class_static()):
				titleBar.theme.clear_icon("title_close_pressed", get_class_static())
			
			if has_font("title_font"):
				titleBar.theme.set_font("font", "Button", get_font("title_font"))
			elif titleBar.theme.has_font("font", "Button"):
				titleBar.theme.clear_font("font", "Button")
			if has_stylebox("title_menu_bg"):
				titleBar.theme.set_stylebox("bg", "PopupMenu", get_stylebox("title_menu_bg"))
			elif titleBar.theme.has_stylebox("bg", "PopupMenu"):
				titleBar.theme.clear_stlyebox("bg", "PopupMenu")
			if has_font("title_menu_font"):
				titleBar.theme.set_font("font", "PopupMenu", get_font("title_menu_font"))
			elif titleBar.theme.has_font("font", "PopupMenu"):
				titleBar.theme.clear_font("font", "PopupMenu")
			
			if _is_using_custom_cursor():
				_use_custom_cursor(get_icon(DRAG_STATE_THEME_NAME[dragState]) if has_icon(DRAG_STATE_THEME_NAME[dragState]) else ICON_THEME_NAMES[DRAG_STATE_THEME_NAME[dragState]])
			
			titleBarTranAnim.minimum_size_changed()
		NOTIFICATION_VISIBILITY_CHANGED:
			if visible:
				_empty_check()
		NOTIFICATION_DRAG_BEGIN:
			_drag_title_begin()
		NOTIFICATION_DRAG_END:
			_drag_title_end()

func _process(p_delta):
	if not isDragingTitle:
		set_process(false)
		return
	if titleBar.get_first_scroll_button().visible:
		titleBar.scroll_front()
	elif titleBar.get_second_scroll_button().visible:
		titleBar.scroll_back()

func _input(p_event):
	if p_event is InputEventKey && get_global_rect().has_point(get_global_mouse_position()):
		if p_event.pressed && not p_event.echo && p_event.scancode == KEY_TAB && not p_event.alt && not p_event.control && not p_event.shift:
			set_show_title_bar(!showTitleBar)
	
	if isDragingTitle && p_event is InputEventMouseMotion:
		var hoverRegion = _get_drag_hover()
		if _is_drag_hover():
			if hoverRegion == null:
				dragHoverEffect.hide()
			elif hoverRegion != dragHoverEffect.get_parent():
				dragHoverEffect.get_parent().remove_child(dragHoverEffect)
				hoverRegion.add_child(dragHoverEffect)
		elif hoverRegion != null:
			if dragHoverEffect == null:
				dragHoverEffect = HoverEffect.new()
			else:
				dragHoverEffect.get_parent().remove_child(dragHoverEffect)
				dragHoverEffect.show()
			hoverRegion.add_child(dragHoverEffect)
	
	if dragState <= DRAG_ON_EDGE:
		return
	
	if p_event is InputEventMouseButton:
		if p_event.button_index == BUTTON_LEFT:
			if p_event.pressed:
				self.dragState = DRAG_NONE
			else:
				get_tree().set_input_as_handled()
				var prevState = dragState
				self.dragState = DRAG_NONE
				if prevState >= DRAG_SPLIT_LEFT && prevState <= DRAG_MERGE_SELF_BOTTOM:
					emit_signal("layout_changed")
	elif p_event is InputEventMouseMotion:
		if !Input.is_mouse_button_pressed(BUTTON_LEFT):
			print("[blenderWnd::_input] Mouse left button not pressed when drag!")
			var prevState = dragState
			self.dragState = DRAG_NONE
			if prevState >= DRAG_SPLIT_LEFT && prevState <= DRAG_MERGE_SELF_BOTTOM:
				emit_signal("layout_changed")
			return
		
		match dragState:
			DRAG_SPLIT_LEFT, DRAG_SPLIT_RIGHT:
				get_parent().set_offset_with_mouse_pos()
			DRAG_SPLIT_TOP, DRAG_SPLIT_BOTTOM:
				get_parent().set_offset_with_mouse_pos()
			DRAG_MERGE_LEFT:
				if get_global_mouse_position().x - rect_global_position.x > 0.0:
					dragState = DRAG_MERGE_SELF_LEFT
					var arrowNode = _get_delete_arrow()
					arrowNode.rect_position = rect_global_position
					arrowNode.rect_size = get_global_rect().size
					arrowNode.flip_h = true
			DRAG_MERGE_SELF_LEFT:
				if get_global_mouse_position().x - rect_global_position.x < 0.0:
					dragState = DRAG_MERGE_LEFT
					var arrowNode = _get_delete_arrow()
					var delWnd = arrowNode.get_meta("delWnd")
					arrowNode.rect_position = delWnd.rect_global_position
					arrowNode.rect_size = delWnd.get_global_rect().size
					arrowNode.flip_h = false
			DRAG_MERGE_RIGHT:
				if get_global_mouse_position().x < get_global_rect().end.x:
					dragState = DRAG_MERGE_SELF_RIGHT
					var arrowNode = _get_delete_arrow()
					arrowNode.rect_position = rect_global_position
					arrowNode.rect_size = get_global_rect().size
					arrowNode.flip_h = false
			DRAG_MERGE_SELF_RIGHT:
				if get_global_mouse_position().x > get_global_rect().end.x:
					dragState = DRAG_MERGE_RIGHT
					var arrowNode = _get_delete_arrow()
					var delWnd = arrowNode.get_meta("delWnd")
					arrowNode.rect_position = delWnd.rect_global_position
					arrowNode.rect_size = delWnd.get_global_rect().size
					arrowNode.flip_h = true
			DRAG_MERGE_TOP:
				if get_global_mouse_position().y - rect_global_position.y > 0.0:
					dragState = DRAG_MERGE_SELF_TOP
					var arrowNode = _get_delete_arrow()
					arrowNode.rect_position = rect_global_position
					arrowNode.rect_size = get_global_rect().size
					arrowNode.flip_v = true
			DRAG_MERGE_SELF_TOP:
				if get_global_mouse_position().y - rect_global_position.y < 0.0:
					dragState = DRAG_MERGE_TOP
					var arrowNode = _get_delete_arrow()
					var delWnd = arrowNode.get_meta("delWnd")
					arrowNode.rect_position = delWnd.rect_global_position
					arrowNode.rect_size = delWnd.get_global_rect().size
					arrowNode.flip_v = false
			DRAG_MERGE_BOTTOM:
				if get_global_mouse_position().y < get_global_rect().end.y:
					dragState = DRAG_MERGE_SELF_BOTTOM
					var arrowNode = _get_delete_arrow()
					arrowNode.rect_position = rect_global_position
					arrowNode.rect_size = get_global_rect().size
					arrowNode.flip_v = false
			DRAG_MERGE_SELF_BOTTOM:
				if get_global_mouse_position().y > get_global_rect().end.y:
					dragState = DRAG_MERGE_BOTTOM
					var arrowNode = _get_delete_arrow()
					var delWnd = arrowNode.get_meta("delWnd")
					arrowNode.rect_position = delWnd.rect_global_position
					arrowNode.rect_size = delWnd.get_global_rect().size
					arrowNode.flip_v = true
		
		get_tree().set_input_as_handled()

func _gui_input(p_event):
	if p_event is InputEventMouseButton:
		if p_event.button_index == BUTTON_LEFT:
			if p_event.pressed:
				if dragState < 0 && _is_corner(p_event.position):
					dragPos = p_event.position
					self.dragState = DRAG_ON_EDGE
			elif dragState == DRAG_ON_EDGE:
				self.dragState = DRAG_NONE
			elif dragState != DRAG_NONE:
				print("[blenderWnd::_gui_input] dragState should be DRAG_NONE, but is ", str(dragState))
				self.dragState = DRAG_NONE
	elif p_event is InputEventMouseMotion && dragState >= DRAG_ON_EDGE:
		match dragState:
			DRAG_ON_EDGE:
				self.dragState = _get_next_state(p_event.position)
			_:
				self.dragState = DRAG_NONE
				print("[blenderWnd::_gui_input] dragState is not DRAG_ON_EDGE")

static func node_set_parent(p_node:Node, p_parent:Node):
	if p_node.get_parent() != null:
		var owners = {}
		var needProcess = [ p_node ]
		var process
		while needProcess.size() > 0:
			process = needProcess.back()
			needProcess.pop_back()
			if process.owner != null:
				owners[process.get_instance_id()] = process.owner
			for i in process.get_children():
				needProcess.append(i)
		p_node.get_parent().remove_child(p_node)
		p_parent.add_child(p_node)
		for i in owners.keys():
			instance_from_id(i).owner = owners[i]
	else:
		p_parent.add_child(p_node)

func _is_corner(p_localPos:Vector2):
	return (p_localPos.x < drag_margin || p_localPos.x > rect_size.x - drag_margin) && \
			(p_localPos.y < leftTopControl.margin_bottom || p_localPos.y > rect_size.y - drag_margin)

func _is_drag_hover() -> bool:
	return dragHoverEffect != null && dragHoverEffect.visible

func _get_drag_hover():
	var mousePos = get_global_mouse_position()
	if not get_global_rect().has_point(mousePos):
		return null
	
	for i in dragRegionEffects:
		if i.get_global_rect().has_point(mousePos):
			return i
	
	return null

func _is_using_custom_cursor():
	return dragState >= DRAG_ON_EDGE && dragState < DRAG_NUM

func _use_custom_cursor(p_cursorImg:Texture):
	Input.set_custom_mouse_cursor(p_cursorImg)
	Input.set_custom_mouse_cursor(p_cursorImg, Input.CURSOR_CROSS)

func _unuse_custom_cursor():
	if _is_using_custom_cursor():
		Input.set_custom_mouse_cursor(null)
		Input.set_custom_mouse_cursor(null, Input.CURSOR_CROSS)

func _get_next_state(p_localMousePos:Vector2):
	if dragState != DRAG_ON_EDGE:
		return dragState
	
	var vec = p_localMousePos - dragPos
	if vec.length() < 3.0:
		return DRAG_ON_EDGE
	
	if abs(vec.x) >= abs(vec.y):
		if vec.x > 0:
			if dragPos.x <= drag_margin:
				return DRAG_SPLIT_LEFT
			else:
				return DRAG_MERGE_RIGHT
		else:
			if dragPos.x <= drag_margin:
				return DRAG_MERGE_LEFT
			else:
				return DRAG_SPLIT_RIGHT
	else:
		if vec.y > 0:
			if dragPos.y <= drag_margin + leftTopControl.rect_position.y:
				return DRAG_SPLIT_TOP
			else:
				return DRAG_MERGE_BOTTOM
		else:
			if dragPos.y <= drag_margin + leftTopControl.rect_position.y:
				return DRAG_MERGE_TOP
			else:
				return DRAG_SPLIT_BOTTOM

func _add_delete_arrow(p_dir, p_deleteWnd:Control):
	var texRect := TextureRect.new()
	texRect.rect_size = p_deleteWnd.get_global_rect().size
	texRect.stretch_mode = TextureRect.STRETCH_SCALE
	texRect.expand = true
	texRect.rect_position = p_deleteWnd.rect_global_position
	match p_dir:
		DIR_LEFT:
			texRect.texture = mergeArrowTex[0]
		DIR_RIGHT:
			texRect.texture = mergeArrowTex[0]
			texRect.flip_h = true
		DIR_UP:
			texRect.texture = mergeArrowTex[1]
		DIR_DOWN:
			texRect.texture = mergeArrowTex[1]
			texRect.flip_v = true
	
	texRect.set_meta("delWnd", p_deleteWnd)
	var layer = CanvasLayer.new()
	layer.layer = 0xFFFFFF - 1
	layer.add_child(texRect)
	add_child(layer)

func _get_delete_arrow():
	var node = get_child(get_child_count() - 1)
	if not node is CanvasLayer:
		return null
	
	return node.get_child(0)


func _split(p_dir:int):
	if p_dir < 0 || p_dir > 3:
		return
	
	var id = get_index()
	var p = get_parent()
	
	var sc:SplitContainer
	if p_dir == DIR_LEFT || p_dir == DIR_RIGHT:
		sc = MyHSplitContainer.new()
		if has_constant_override("split_h_separation"):
			sc.add_constant_override("split_h_separation", get_constant("split_h_separation"))
		if has_icon_override("split_h_grabber"):
			sc.add_icon_override("split_h_grabber", get_icon("split_h_grabber"))
		if has_stylebox_override("split_h_bg"):
			sc.add_stylebox_override("split_h_bg", get_stylebox("split_h_bg"))
	else:
		sc = MyVSplitContainer.new()
		if has_constant_override("split_v_separation"):
			sc.add_constant_override("split_v_separation", get_constant("split_v_separation"))
		if has_icon_override("split_v_grabber"):
			sc.add_icon_override("split_v_grabber", get_icon("split_v_grabber"))
		if has_stylebox_override("split_v_bg"):
			sc.add_stylebox_override("split_v_bg", get_stylebox("split_v_bg"))
	
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

	p.add_child(sc)
	if owner != null:
		sc.owner = owner
	var newWnd = _new_wnd()
	if p_dir == DIR_LEFT || p_dir == DIR_UP:
		sc.add_child(newWnd)
		node_set_parent(self, sc)
	else:
		node_set_parent(self, sc)
		sc.add_child(newWnd)

	p.move_child(sc, id)
	
	if p_dir == DIR_LEFT || p_dir == DIR_RIGHT:
		sc.split_offset = get_global_mouse_position().x - sc.rect_global_position.x - sc.get_child(0).rect_min_size.x
	else:
		sc.split_offset = get_global_mouse_position().y - sc.rect_global_position.y - sc.get_child(0).rect_min_size.y
	sc.clamp_split_offset()

func _new_wnd():
	var newWnd = get_script().new()
	newWnd.wndFactories = wndFactories
	newWnd.drag_margin = drag_margin
	newWnd.theme = theme
	newWnd.defaultShowTitleBar = defaultShowTitleBar
	newWnd.showTitleBar = newWnd.defaultShowTitleBar
	newWnd.defaultWndFactoryId = defaultWndFactoryId
	newWnd._set_ratio(size_flags_stretch_ratio)
	newWnd.copy_signal_connect(self, "child_wnd_closed")
	newWnd.copy_signal_connect(self, "child_wnd_created")
	newWnd.copy_signal_connect(self, "child_wnd_toggled")
	newWnd.copy_signal_connect(self, "layout_changed")

	return newWnd

func copy_signal_connect(p_target, p_signal:String):
	var signalList = p_target.get_signal_connection_list(p_signal)
	for i in signalList:
		if i.has("bind"):
			connect(p_signal, i["target"], i["method"], i["bind"])
		else:
			connect(p_signal, i["target"], i["method"])

func _set_ratio(p_ratio):
	size_flags_stretch_ratio = p_ratio
	if get_parent() is SplitContainer:
		for i in get_parent().get_children():
			if i == self:
				continue
			i.size_flags_stretch_ratio = 1.0 - p_ratio

func _remove_wnd(p_wnd):
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

func _find_delete_wnd(p_dir:int):
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
	
	find = _find_parent_by_class(findClass)
	while find != null && find.get_child(selfId) != self && not find.get_child(selfId).is_a_parent_of(self):
		find = _find_parent_by_class(findClass, find)
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


func _find_parent_by_class(p_class, p_node = self):
	var parent = p_node.get_parent()
	while parent != null && not parent is p_class:
		parent = parent.get_parent()
	
	return parent

func set_show_title_bar(p_value:bool):
	if p_value == showTitleBar:
		return
	showTitleBar = p_value
	if showTitleBar:
		titleBarTranAnim.show()
		leftTopControl.margin_top = titleBar.rect_size.y
		leftTopControl.margin_bottom = drag_margin + leftTopControl.margin_top
	else:
		titleBarTranAnim.hide()
		leftTopControl.margin_top = 0.0
		leftTopControl.margin_bottom = drag_margin
	rightTopControl.margin_top = leftTopControl.margin_top
	rightTopControl.margin_bottom = leftTopControl.margin_bottom

func set_drag_margin(p_value:float):
	if drag_margin == p_value:
		return
	
	drag_margin = p_value
	leftTopControl.margin_right = drag_margin
	leftTopControl.margin_bottom = drag_margin
	rightTopControl.margin_left = -drag_margin
	rightTopControl.margin_bottom = drag_margin
	rightBottomControl.margin_top = -drag_margin
	rightBottomControl.margin_left = -drag_margin
	leftBottomControl.margin_right = drag_margin
	leftBottomControl.margin_top = -drag_margin

func _create_title_node():
	var ret = preload("titleBtn.tscn").instance()
	ret.group = titleBarBtnGroup
	ret.connect("mouse_in", self, "_on_titleNode_mouse_in", [ret])
	ret.connect("mouse_out", self, "_on_titleNode_mouse_out", [ret])
	ret.connect("close", self, "_on_titleNode_close", [ret])
	ret.set_drag_forwarding(self)
	ret.get_icon_btn().get_popup().set_drag_forwarding(self)
	ret.get_icon_btn().connect("item_selected", self, "_on_titleNode_item_selected", [ret])
	var iconNode = ret.get_icon_btn()
	for i in wndFactories.size():
		if wndFactories[i] != null && wndFactories[i] is BlenderWndFactory:
			iconNode.add_icon_item(wndFactories[i].get_icon(), wndFactories[i].get_title(), i)
		else:
			iconNode.add_item(str(i), i)
	ret.connect("pressed", self, "_on_titleNode_pressed", [ret])
	return ret

func _is_drop_valid(p_data) -> bool:
	return p_data != null && p_data is Dictionary && p_data.has("type") && p_data["type"] == "blenderWndChildWnd"

func can_drop_data_fw(p_pos, p_data, p_from):
	return p_from in dragRegionEffects && _is_drop_valid(p_data)

func drop_data_fw(p_pos, p_data, p_from):
	if not _is_drop_valid(p_data):
		return
	
	var id =  p_data["from"].get_index()
	if p_data["blenderWndChildWnd"] != null && p_data["blenderWnd"] != self:
		var fromWnd = p_data["blenderWnd"]
		var fromTitleNode = p_data["from"]
		fromWnd.childWnds[fromTitleNode.get_index()] = null
		node_set_parent(p_data["blenderWndChildWnd"], wndControl)
		var factoryId = fromTitleNode.get_icon_btn().get_item_index(fromTitleNode.get_icon_btn().get_selected_id())
		var factory
		if factoryId >= 0 && factoryId < fromWnd.wndFactories.size():
			factory = fromWnd.wndFactories[factoryId]
		if factory != null:
			factoryId = add_wnd_factory(factory)
		else:
			factoryId = -1
		new_child_wnd(factoryId, p_data["blenderWndChildWnd"])
		id = childWnds.size() - 1
		fromWnd.close_child_wnd(fromTitleNode.get_index())
	
	var targetId = p_from.get_meta("region_id")
	move_child_wnd(id, targetId)
	set_current_child_wnd_id(targetId)

func _create_drag_preview(p_iconBtn:OptionButton):
	var preview = TextureRect.new()
	preview.texture = p_iconBtn.get_item_icon(p_iconBtn.get_item_index(p_iconBtn.get_selected_id()))
	preview.minimum_size_changed()
	preview.rect_size = preview.get_minimum_size()
	var text = Label.new()
	text.text = p_iconBtn.get_item_text(p_iconBtn.get_item_index(p_iconBtn.get_selected_id()))
	text.minimum_size_changed()
	text.rect_position = Vector2((preview.rect_size.x - text.get_minimum_size().x) / 2.0, preview.rect_size.y)
	preview.add_child(text)
	return preview

func get_drag_data_fw(p_pos, p_from):
	if p_from is Popup:
		p_from.hide()
		p_from = p_from.get_parent().get_parent()
	elif not p_from is TitleBtn:
		return null
	
	set_drag_preview(_create_drag_preview(p_from.get_icon_btn()))
	return { "type":"blenderWndChildWnd", "blenderWndChildWnd":childWnds[p_from.get_index()], "blenderWnd":self, "from":p_from}

func _drag_title_begin():
	if not _is_drop_valid(get_tree().root.gui_get_drag_data()):
		return
	
	isDragingTitle = true
	_update_drag_region()

func _drag_title_end():
	if not isDragingTitle:
		return
	isDragingTitle = false
	_update_drag_region()

func _update_drag_region():
	if not isDragingTitle:
		for i in dragRegionEffects:
			i.queue_free()
		dragRegionEffects.clear()
		if dragHoverEffect != null:
			dragHoverEffect.queue_free()
		set_process(false)
		return
	var dragData = get_tree().root.gui_get_drag_data()
	var newRegion = []
	var region
	if showTitleBar:
		for i in titleBar.get_children():
			if i == dragData["from"] || i == addWndBtn || i.rect_position.x > titleBar.get_scroll() + titleBar.rect_size.x || i.rect_position.x + i.rect_size.x < titleBar.get_scroll():
				continue
			
			if dragRegionEffects.size() > 0:
				region = dragRegionEffects.back()
				dragRegionEffects.pop_back()
			else:
				region = SelectEffect.new()
				region.set_drag_forwarding(self)
			region.rect_position = Vector2(i.rect_position.x - titleBar.get_scroll(), 0.0)
			region.rect_size = Vector2(min(i.rect_size.x, titleBar.rect_size.x - region.rect_position.x), titleBar.rect_size.y)
			region.set_meta("region_id", i.get_index())
			if region.get_parent() == null:
				add_child(region)
			newRegion.append(region)
		
		if dragData["blenderWnd"] != self || dragData["from"].get_index() != childWnds.size() - 1:
			var lastRegion = addWndBtn.rect_position.x - titleBar.get_scroll()
			if lastRegion < titleBar.rect_size.x:
				if dragRegionEffects.size() > 0:
					region = dragRegionEffects.back()
					dragRegionEffects.pop_back()
				else:
					region = SelectEffect.new()
					region.set_drag_forwarding(self)
				region.rect_position = Vector2(lastRegion, 0.0)
				region.rect_size = Vector2(titleBar.rect_size.x - lastRegion, titleBar.rect_size.y)
				region.set_meta("region_id", childWnds.size())
				if region.get_parent() == null:
					add_child(region)
				newRegion.append(region)
	
	if dragData["blenderWnd"] != self || dragData["from"].get_index() != childWnds.size() - 1:
		if dragRegionEffects.size() > 0:
			region = dragRegionEffects.back()
			dragRegionEffects.pop_back()
		else:
			region = SelectEffect.new()
			region.set_drag_forwarding(self)
		region.rect_position = wndControl.rect_position + Vector2(1.0, 1.0)
		region.rect_size = wndControl.rect_size - Vector2(2.0, 2.0)
		region.set_meta("region_id", childWnds.size())
		if region.get_parent() == null:
			add_child(region)
		newRegion.append(region)
		
	for i in dragRegionEffects:
		i.queue_free()
	dragRegionEffects = newRegion
	set_process(true)


func set_child_wnd_factory(p_wndId, p_factoryId:int, p_check := true):
	var button:OptionButton = titleBar.get_child(p_wndId).get_icon_btn()
	var prevFactoryId = button.get_item_index(button.get_selected_id())
	if wndFactories.size() <= 0:
		if childWnds[p_wndId]:
			childWnds[p_wndId].queue_free()
		childWnds[p_wndId] = null
		button.select(-1)
		return
	
	if p_factoryId < 0 || p_factoryId >= wndFactories.size():
		if defaultWndFactoryId >= 0 && defaultWndFactoryId < wndFactories.size():
			p_factoryId = defaultWndFactoryId
		else:
			p_factoryId = 0
	
	if p_check && prevFactoryId == p_factoryId:
		return

	if childWnds[p_wndId]:
		childWnds[p_wndId].queue_free()
	
	if wndFactories[p_factoryId] != null && wndFactories[p_factoryId] is BlenderWndFactory:
		childWnds[p_wndId] = wndFactories[p_factoryId].create_wnd()
	else:
		childWnds[p_wndId] = null
	
	button.select(p_factoryId)

	if childWnds[p_wndId] != null:
		if is_inside_tree() && currentChildWndId == p_wndId:
			childWnds[p_wndId].show()
		else:
			childWnds[p_wndId].hide()
		wndControl.add_child(childWnds[p_wndId])

func set_current_child_wnd_id(p_value:int):
	if p_value == currentChildWndId:
		return
	
	if currentChildWndId >=0 && currentChildWndId < childWnds.size() && childWnds[currentChildWndId] != null:
		childWnds[currentChildWndId].hide()
	currentChildWndId = p_value
	
	_current_child_wnd_check()

func set_drag_state(p_value):
	if p_value == dragState || p_value < DRAG_NONE || p_value >= DRAG_NUM:
		return
	
	_unuse_custom_cursor()
	var prevState = dragState
	dragState = p_value
	
	if prevState == DRAG_ON_EDGE:
		match dragState:
			DRAG_MERGE_LEFT, DRAG_MERGE_RIGHT, DRAG_MERGE_TOP, DRAG_MERGE_BOTTOM:
				var delWnd = _find_delete_wnd(dragState - DRAG_MERGE_LEFT)
				
				if delWnd == null:
					dragState = DRAG_BAN
				else:
					_add_delete_arrow(dragState - DRAG_MERGE_LEFT, delWnd)
			DRAG_SPLIT_LEFT, DRAG_SPLIT_RIGHT, DRAG_SPLIT_TOP, DRAG_SPLIT_BOTTOM:
				if ((dragState == DRAG_SPLIT_LEFT || dragState == DRAG_SPLIT_RIGHT) && rect_size.x <= get_minimum_size().x * 2.0) || \
						((dragState == DRAG_SPLIT_TOP || dragState == DRAG_SPLIT_BOTTOM) && rect_size.y <= get_minimum_size().y * 2.0):
					dragState = DRAG_BAN
				else:
					_split(dragState - DRAG_SPLIT_LEFT)
	elif dragState == DRAG_NONE:
		match prevState:
			DRAG_MERGE_LEFT, DRAG_MERGE_RIGHT, DRAG_MERGE_TOP, DRAG_MERGE_BOTTOM:
				var arrowNode = _get_delete_arrow()
				if arrowNode:
					remove_child(arrowNode.get_parent())
					var delWnd = arrowNode.get_meta("delWnd")
					arrowNode.queue_free()
					_remove_wnd(delWnd)
			DRAG_MERGE_SELF_LEFT, DRAG_MERGE_SELF_RIGHT, DRAG_MERGE_SELF_TOP, DRAG_MERGE_SELF_BOTTOM:
				_remove_wnd(self)
	if DRAG_STATE_THEME_NAME.has(dragState):
		_use_custom_cursor(get_icon(DRAG_STATE_THEME_NAME[dragState]) if has_icon(DRAG_STATE_THEME_NAME[dragState]) else ICON_THEME_NAMES[DRAG_STATE_THEME_NAME[dragState]])

func get_drag_state() -> int:
	return dragState

func new_child_wnd(p_factoryId = -1, p_wnd = null, p_pos := -1):
	var titleNode = _create_title_node()
	if wndFactories.size() > 0:
		if p_factoryId < 0 || p_factoryId >= wndFactories.size():
			p_factoryId = _get_default_factory()
	
		if p_wnd == null && wndFactories[p_factoryId] != null && wndFactories[p_factoryId] is BlenderWndFactory:
			p_wnd = wndFactories[p_factoryId].create_wnd()
		
		titleNode.get_icon_btn().select(p_factoryId)
	
	titleBar.add_child(titleNode)
	
	if p_pos < 0 || p_pos > childWnds.size():
		titleBar.move_child(titleNode, childWnds.size())
		childWnds.append(p_wnd)
	else:
		titleBar.move_child(titleNode, p_pos)
		childWnds.insert(p_pos, p_wnd)
		if currentChildWndId >= p_pos:
			currentChildWndId += 1
	
	if p_wnd != null:
		p_wnd.hide()
		if p_wnd.get_parent() == null:
			wndControl.add_child(p_wnd)
	
	_current_child_wnd_check()

func close_child_wnd(p_id:int):
	if p_id < 0 || p_id >= childWnds.size():
		return
	
	if currentChildWndId == p_id:
		if childWnds.size() > 1:
			set_current_child_wnd_id(p_id - 1 if p_id > 0 else p_id + 1)
		else:
			set_current_child_wnd_id(-1)
	var titleNode = titleBar.get_child(p_id)
	titleBar.remove_child(titleNode)
	var wnd = childWnds[p_id]
	childWnds.remove(p_id)

	titleNode.queue_free()
	if wnd != null:
		wnd.queue_free()
	
	_empty_check()

func get_child_wnd(p_id) -> Node:
	if p_id < 0 || p_id >= childWnds.size():
		return null
	
	return childWnds[p_id]

func get_child_wnd_id(p_wnd) -> int:
	return childWnds.find(p_wnd)

func get_child_wnd_count() -> int:
	return childWnds.size()

func _on_titleBar_resized():
	if showTitleBar:
		leftTopControl.margin_top = titleBar.rect_size.y
		leftTopControl.margin_bottom = leftTopControl.margin_top + drag_margin
		rightTopControl.margin_top = leftTopControl.margin_top
		rightTopControl.margin_bottom = leftTopControl.margin_bottom

func _on_addWndBtn_pressed():
	new_child_wnd()
	set_current_child_wnd_id(childWnds.size() - 1)
	emit_signal("child_wnd_created")

func _on_titleNode_pressed(p_titleBtn):
	set_current_child_wnd_id(p_titleBtn.get_index())
	emit_signal("child_wnd_toggled")

func _on_titleNode_mouse_in(p_titleBtn):
	if childWnds.size() > 1:
		p_titleBtn.get_close_btn().show()

func _on_titleNode_mouse_out(p_titleBtn):
	p_titleBtn.get_close_btn().hide()

func _on_titleNode_close(p_titleBtn):
	if childWnds.size() < 2:
		return
	
	close_child_wnd(p_titleBtn.get_index())
	emit_signal("child_wnd_closed")

func _on_titleNode_item_selected(p_index, p_titleNode):
	set_child_wnd_factory(p_titleNode.get_index(), p_index, false)

func _get_default_factory():
	if defaultWndFactoryId >= 0 && defaultWndFactoryId < wndFactories.size():
		return defaultWndFactoryId
	return 0

func set_wnd_factories(p_value:Array):
	var default = defaultWndFactoryId if defaultWndFactoryId >= 0 && defaultWndFactoryId < p_value.size() else 0
	if p_value.size() <= 0:
		default = -1
	
	var factoryMap = []
	factoryMap.resize(wndFactories.size())
	for i in wndFactories.size():
		factoryMap[i] = default
		if wndFactories[i] != null:
			for j in p_value.size():
				if p_value[j] == null:
					continue
				if p_value[j] != null && wndFactories[i].get_script() == p_value[j].get_script():
					factoryMap[i] = j
					break
	
	var prevId
	var targetId
	var node
	for i in childWnds.size():
		node = titleBar.get_child(i).get_icon_btn()
		prevId = node.get_item_index(node.get_selected_id())
		node.clear()
		for j in p_value.size():
			if p_value[j] != null && p_value[j] is BlenderWndFactory:
				node.add_icon_item(p_value[j].get_icon(), p_value[j].get_title(), j)
			else:
				node.add_item(str(j), j)
		if prevId >= 0 && prevId < factoryMap.size():
			targetId = factoryMap[prevId]
		else:
			targetId = default
		
		node.select(targetId)
		if targetId < 0 || prevId < 0 || prevId >= wndFactories.size() || wndFactories[prevId] == null || \
				wndFactories[prevId].get_script() != p_value[targetId].get_script():
			if childWnds[i] != null:
				childWnds[i].queue_free()
			
			if targetId >= 0 && p_value[targetId] != null && p_value[targetId] is BlenderWndFactory:
				childWnds[i] = p_value[targetId].create_wnd()
				if childWnds[i] != null:
					wndControl.add_child(childWnds[i])
					if currentChildWndId == i:
						childWnds[i].show()
					else:
						childWnds[i].hide()
			else:
				childWnds[i] = null
		
	wndFactories = p_value


func add_wnd_factory(p_factory) -> int:
	var find = wndFactories.find(p_factory)
	if find >= 0:
		return find
	wndFactories.append(p_factory)
	
	var node
	for i in childWnds.size():
		node = titleBar.get_child(i)
		if p_factory != null && p_factory is BlenderWndFactory:
			node.add_icon_item(p_factory.get_icon(), p_factory.get_title(), node.get_item_count())
		else:
			node.add_item(str(node.get_item_count()), node.get_item_count())
	
	return wndFactories.size() - 1

func add_wnd_factories(p_factories:Array) -> PoolIntArray:
	var added = []
	var ret = PoolIntArray()
	var find
	for i in p_factories:
		find = wndFactories.find(i)
		if find >= 0:
			ret.append(find)
			continue
		ret.append(wndFactories.size())
		wndFactories.append(i)
		added.append(i)
	
	var node
	for i in childWnds.size():
		node = titleBar.get_child(i)
		for j in added:
			if j != null && j is BlenderWndFactory:
				node.add_icon_item(j.get_icon(), j.get_title(), node.get_item_count())
			else:
				node.add_item(str(node.get_item_count()), node.get_item_count())
	
	return ret

func move_wnd_factory(p_factoryId:int, p_pos:int) -> int:
	if p_factoryId < 0 || p_factoryId >= wndFactories.size():
		return -1
	
	p_pos = min(max(p_pos, 0), wndFactories.size())
	if p_factoryId == p_pos || (p_factoryId == wndFactories.size() -1 && p_pos == wndFactories.size()):
		return p_factoryId
	
	var factory = wndFactories[p_factoryId]
	wndFactories.insert(p_pos, factory)
	if p_pos > p_factoryId:
		wndFactories.remove(p_factoryId)
	else:
		wndFactories.remove(p_factoryId + 1)
	
	var node
	for i in childWnds.size():
		node = titleBar.get_child(i)
		node.clear()
		for j in wndFactories.size():
			if wndFactories[j] != null && wndFactories[j] is BlenderWndFactory:
				node.add_icon_item(wndFactories[j].get_icon(), wndFactories[j].get_title(), j)
			else:
				node.add_item(str(j), j)
	return int(min(p_pos, wndFactories.size() -1))

func get_wnd_factory_id(p_factory) -> int:
	return wndFactories.find(p_factory)

func move_child_wnd(p_childWndId:int, p_pos:int):
	if p_childWndId < 0 || p_childWndId >= childWnds.size():
		return -1
	
	p_pos = min(max(p_pos, 0), childWnds.size())
	if p_childWndId == p_pos || (p_childWndId == childWnds.size() -1 && p_pos == childWnds.size()):
		return p_childWndId
	
	if p_pos == childWnds.size():
		titleBar.move_child(titleBar.get_child(p_childWndId), p_pos - 1)
	else:
		titleBar.move_child(titleBar.get_child(p_childWndId), p_pos)
	childWnds.insert(p_pos, childWnds[p_childWndId])
	if p_pos > p_childWndId:
		childWnds.remove(p_childWndId)
	else:
		childWnds.remove(p_childWndId + 1)

func save_layout(p_savePath:String):
	var o = get_top()
	var needProcess = []
	if o is SplitContainer:
		needProcess.append(o.get_child(0))
		needProcess.append(o.get_child(1))
	var process
	while needProcess.size() > 0:
		process = needProcess.back()
		needProcess.pop_back()
		if process is SplitContainer:
			needProcess.append(process.get_child(0))
			needProcess.append(process.get_child(1))
		process.owner = o
	
	var dir = Directory.new()
	dir.make_dir_recursive(p_savePath.get_base_dir())
	
	var packed = PackedScene.new()
	var err = packed.pack(o)
	if err != OK:
		return err
	
	err = ResourceSaver.save(p_savePath, packed, ResourceSaver.FLAG_OMIT_EDITOR_PROPERTIES)
	return err

func get_top() -> Node:
	var p = get_parent()
	var ret = self
	while p != null && (p is MyHSplitContainer || p is MyVSplitContainer):
		if p.get_child_count() != 2 || (not p.get_child(0) is get_script() && not p.get_child(0) is MyHSplitContainer && not p.get_child(0) is MyVSplitContainer) || \
				(not p.get_child(1) is get_script() && not p.get_child(1) is MyHSplitContainer && not p.get_child(1) is MyVSplitContainer):
			break
		
		ret = p
		p = p.get_parent()
	
	return ret

func _get(p_property:String):
	if p_property == "wndFactories":
		return self.wndFactories

	var array = p_property.split("/", true, 1)
	if array.size() < 2 || array[0] != get_class_static():
		return null
	if array[1] == "child_wnd_data":
		return _get_child_wnd_data()
	if CONSTANT_THEME_NAMES.has(array[1]):
		return get_constant(array[1]) if has_constant_override(array[1]) else CONSTANT_THEME_NAMES[array[1]]
	elif ICON_THEME_NAMES.has(array[1]):
		return get_icon(array[1]) if has_icon_override(array[1]) else ICON_THEME_NAMES[array[1]]
	elif STYLEBOX_THEME_NAMES.has(array[1]):
		return get_stylebox(array[1]) if has_stylebox_override(array[1]) else STYLEBOX_THEME_NAMES[array[1]]
	elif FONT_THEME_NAMES.has(array[1]):
		return get_font(array[1]) if has_font_override(array[1]) else FONT_THEME_NAMES[array[1]]
	return null

func _set(p_property:String, p_value):
	if p_property == "wndFactories":
		self.wndFactories = p_value
		return true

	var array = p_property.split("/", true, 1)
	if array.size() < 2 || array[0] != get_class_static():
		return false
	if array[1] == "child_wnd_data":
		_set_child_wnd_data(p_value)
		return true

	if CONSTANT_THEME_NAMES.has(array[1]):
		if has_constant_override(array[1]) || p_value != null:
			add_constant_override(array[1], p_value)
		else:
			add_constant_override(array[1], CONSTANT_THEME_NAMES[array[1]])
	elif ICON_THEME_NAMES.has(array[1]):
		if has_icon_override(array[1]) || p_value != null:
			add_icon_override(array[1], p_value)
		else:
			add_icon_override(array[1], ICON_THEME_NAMES[array[1]])
	elif STYLEBOX_THEME_NAMES.has(array[1]):
		if has_stylebox_override(array[1]) || p_value != null:
			add_stylebox_override(array[1], p_value)
		else:
			add_stylebox_override(array[1], STYLEBOX_THEME_NAMES[array[1]])
	elif FONT_THEME_NAMES.has(array[1]):
		if has_font_override(array[1]) || p_value != null:
			add_font_override(array[1], p_value)
		else:
			add_font_override(array[1], FONT_THEME_NAMES[array[1]])
	else:
		return false

	return true

func _get_child_wnd_data():
	var childWndFactoryData = []
	childWndFactoryData.resize(titleBar.get_child_count() - 1)
	var node
	for i in childWndFactoryData.size():
		node = titleBar.get_child(i).get_icon_btn()
		childWndFactoryData[i] = node.get_item_index(node.get_selected_id())
	var wnds = []
	wnds.resize(childWnds.size())
	for i in childWnds.size():
		if childWnds[i] != null:
			wnds[i] = PackedScene.new()
			wnds[i].pack(childWnds[i])
			wnds[i].property_list_changed_notify()
		else:
			wnds[i] = null
	return [ wnds, childWndFactoryData ]

func _set_child_wnd_data(p_value):
	if not p_value is Array || p_value.size() != 2:
		return
	
	for i in p_value[0].size():
		if p_value[0][i] != null && p_value[0][i] is PackedScene && p_value[0][i].can_instance():
			p_value[0][i] = p_value[0][i].instance()
		else:
			p_value[0][i] = null
	
	for i in wndControl.get_children():
		if p_value[0].find(i) < 0:
			wndControl.remove_child(i)
			i.queue_free()
	
	for i in p_value[0]:
		if i != null && i.get_parent() == null:
			wndControl.add_child(i)
			i.hide()
	
	if currentChildWndId >= 0 && currentChildWndId < childWnds.size():
		if childWnds[currentChildWndId] != null && is_instance_valid(childWnds[currentChildWndId]):
			childWnds[currentChildWndId].hide()
	
	childWnds = p_value[0].duplicate()
	
	var node
	var titleCount = titleBar.get_child_count() - 1
	if  titleCount < p_value[1].size():
		for i in range(titleCount, p_value[1].size()):
			node = _create_title_node()
			titleBar.add_child(node)
			titleBar.move_child(node, titleBar.get_child_count() - 2)
	elif titleCount > p_value[1].size():
		for i in range(p_value[1].size(), titleCount):
			node = titleBar.get_child(p_value[1].size())
			titleBar.remove_child(node)
			node.queue_free()
	
	for i in p_value[1].size():
		titleBar.get_child(i).get_icon_btn().select(p_value[1][i])
	
	_current_child_wnd_check()

func _get_property_list():
	var ret = []

	ret.append({ "name":"wndFactories", "type":TYPE_ARRAY, "hint_string":str(TYPE_OBJECT) + "/" + str(PROPERTY_HINT_RESOURCE_TYPE) + ":BlenderWndFactory", "usage":PROPERTY_USAGE_DEFAULT})
	
	for i in range(0, THEMES.size(), 2):
		call(THEME_METHODS[THEMES[i]], ret, THEMES[i + 1])
	
	ret.append({ "name":get_class_static() + "/child_wnd_data", "type":TYPE_ARRAY, "hint_string":str(TYPE_ARRAY), "usage":PROPERTY_USAGE_STORAGE })
	return ret

static func _register_default_theme(p_theme:MyTheme):
	for i in CONSTANT_THEME_NAMES.keys():
		p_theme.set_constant(i, CLASS_NAME, CONSTANT_THEME_NAMES[i])

	for i in ICON_THEME_NAMES.keys():
		if ICON_THEME_NAMES[i] == null:
			continue
		p_theme.set_icon(i, CLASS_NAME, ICON_THEME_NAMES[i])

	for i in STYLEBOX_THEME_NAMES.keys():
		if STYLEBOX_THEME_NAMES[i] == null:
			continue
		p_theme.set_stylebox(i, CLASS_NAME, STYLEBOX_THEME_NAMES[i])

	for i in FONT_THEME_NAMES.keys():
		if FONT_THEME_NAMES[i] == null:
			continue
		p_theme.set_font(i, CLASS_NAME, FONT_THEME_NAMES[i])

func _property_add_group(p_list:Array, p_name:String):
	p_list.append({ "name":p_name, "type":TYPE_NIL, "hint_string":get_class_static() + "/" + p_name.to_lower() + "_", "usage":PROPERTY_USAGE_GROUP })

func _property_add_icon(p_list:Array, p_name:String):
	if has_icon_override(p_name):
		p_list.append({ "name":get_class_static() + "/" + p_name, "type":TYPE_OBJECT, "hint":PROPERTY_HINT_RESOURCE_TYPE, 
				"hint_string":"Texture", "usage":PROPERTY_USAGE_DEFAULT|PROPERTY_USAGE_CHECKABLE|PROPERTY_USAGE_CHECKED })
	else:
		p_list.append({ "name":get_class_static() + "/" + p_name, "type":TYPE_OBJECT, "hint":PROPERTY_HINT_RESOURCE_TYPE, 
				"hint_string":"Texture", "usage":PROPERTY_USAGE_EDITOR|PROPERTY_USAGE_CHECKABLE })

func _property_add_stylebox(p_list:Array, p_name:String):
	if has_stylebox_override(p_name):
		p_list.append({ "name":get_class_static() + "/" + p_name, "type":TYPE_OBJECT, "hint":PROPERTY_HINT_RESOURCE_TYPE, 
				"hint_string":"StyleBox", "usage":PROPERTY_USAGE_DEFAULT|PROPERTY_USAGE_CHECKABLE|PROPERTY_USAGE_CHECKED })
	else:
		p_list.append({ "name":get_class_static() + "/" + p_name, "type":TYPE_OBJECT, "hint":PROPERTY_HINT_RESOURCE_TYPE, 
				"hint_string":"StyleBox", "usage":PROPERTY_USAGE_EDITOR|PROPERTY_USAGE_CHECKABLE })

func _property_add_constant(p_list:Array, p_name:String):
	if has_constant_override(p_name):
		p_list.append({ "name":get_class_static() + "/" + p_name, "type":TYPE_INT, "usage":PROPERTY_USAGE_DEFAULT|PROPERTY_USAGE_CHECKABLE|PROPERTY_USAGE_CHECKED })
	else:
		p_list.append({ "name":get_class_static() + "/" + p_name, "type":TYPE_INT, "usage":PROPERTY_USAGE_EDITOR|PROPERTY_USAGE_CHECKABLE })

func _property_add_font(p_list:Array, p_name:String):
	if has_font_override(p_name):
		p_list.append({ "name":get_class_static() + "/" + p_name, "type":TYPE_OBJECT, "hint":PROPERTY_HINT_RESOURCE_TYPE, 
				"hint_string":"Font", "usage":PROPERTY_USAGE_DEFAULT|PROPERTY_USAGE_CHECKABLE|PROPERTY_USAGE_CHECKED })
	else:
		p_list.append({ "name":get_class_static() + "/" + p_name, "type":TYPE_OBJECT, "hint":PROPERTY_HINT_RESOURCE_TYPE, 
				"hint_string":"Font", "usage":PROPERTY_USAGE_EDITOR|PROPERTY_USAGE_CHECKABLE })

func has_constant(p_name:String, p_type:String = "") -> bool:
	if p_type == "" && not has_constant_override(p_name) && CONSTANT_THEME_NAMES.has(p_name):
		p_type = get_class_static()
	return .has_constant(p_name, p_type)

func has_icon(p_name:String, p_type:String = "") -> bool:
	if p_type == "" && not has_icon_override(p_name) && ICON_THEME_NAMES.has(p_name):
		p_type = get_class_static()
	return .has_icon(p_name, p_type)

func has_font(p_name:String, p_type:String = "") -> bool:
	if p_type == "" && not has_font_override(p_name) && FONT_THEME_NAMES.has(p_name):
		p_type = get_class_static()
	return .has_font(p_name, p_type)

func has_stylebox(p_name:String, p_type:String = "") -> bool:
	if p_type == "" && not has_stylebox_override(p_name) && STYLEBOX_THEME_NAMES.has(p_name):
		p_type = get_class_static()
	return .has_stylebox(p_name, p_type)

func get_constant(p_name:String, p_type:String = ""):
	if p_type == "" && not has_constant_override(p_name) && CONSTANT_THEME_NAMES.has(p_name):
		p_type = get_class_static()
	return .get_constant(p_name, p_type)

func get_icon(p_name:String, p_type:String = ""):
	if p_type == "" && not has_icon_override(p_name) && ICON_THEME_NAMES.has(p_name):
		p_type = get_class_static()
	return .get_icon(p_name, p_type)

func get_font(p_name:String, p_type:String = ""):
	if p_type == "" && not has_font_override(p_name) && FONT_THEME_NAMES.has(p_name):
		p_type = get_class_static()
	return .get_font(p_name, p_type)

func get_stylebox(p_name:String, p_type:String = ""):
	if p_type == "" && not has_stylebox_override(p_name) && STYLEBOX_THEME_NAMES.has(p_name):
		p_type = get_class_static()
	return .get_stylebox(p_name, p_type)

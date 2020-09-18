tool
extends Control

var lineWidth:float = 2.0 setget set_line_width
export var lineColor:Color = Color(0x0285FFFF) setget set_line_color
export var blockColor:Color = Color(0x85BEF3FF) setget set_block_color
export(float, 0.0, 1.0, 0.01) var blockLen:float = 0.05 setget set_block_len
export(float, 0.0, 1.0, 0.01) var blockPos:float = 0.0 setget set_block_pos		# 0.0 is 3 o'clock direction
export var blockSpd:float = 0.4			# ccw when positive

var perimeterDirty := true
var perimeter:float
var hRatio:float
var halfHRatio:float
var wRatio:float
var pointRatios:Array = []
var halfLineWidth:float

func _ready():
	update()

func _notification(what):
	match what:
		NOTIFICATION_RESIZED:
			perimeterDirty = true

func _update_perimeter():
	perimeterDirty = false
	halfLineWidth = lineWidth * 0.5
	perimeter = (rect_size.x + rect_size.y - lineWidth * 2.0) * 2.0
	hRatio = (rect_size.y - lineWidth) / perimeter
	halfHRatio = hRatio * 0.5
	wRatio = (rect_size.x - lineWidth) / perimeter
	pointRatios = [ halfHRatio, halfHRatio + wRatio, halfHRatio + wRatio + hRatio, halfHRatio + wRatio * 2.0 + hRatio]

func _ratio_to_pos(p_ratio:float):
	if p_ratio < pointRatios[0]:
		return Vector2(rect_size.x - halfLineWidth, (pointRatios[0] - p_ratio) * perimeter)
	elif p_ratio < pointRatios[1]:
		return Vector2(rect_size.x - halfLineWidth - (p_ratio - pointRatios[0]) * perimeter, 0.0)
	elif p_ratio < pointRatios[2]:
		return Vector2(0.0, (p_ratio - pointRatios[1]) * perimeter)
	elif p_ratio < pointRatios[3]:
		return Vector2((p_ratio - pointRatios[2]) * perimeter, rect_size.y - halfLineWidth)
	else:
		return Vector2(rect_size.x - halfLineWidth, rect_size.y - halfLineWidth - (p_ratio - pointRatios[3]) * perimeter)

func _process(p_delta):
	self.blockPos = fmod(blockPos + blockSpd * p_delta, 1.0)

func _draw():
	if perimeterDirty:
		_update_perimeter()
	
	if perimeter <= 0.0:
		return
	
	var halfLineWidth = lineWidth * 0.5
	var points = [Vector2(rect_size.x - halfLineWidth, halfLineWidth), Vector2(halfLineWidth, halfLineWidth), Vector2(halfLineWidth, rect_size.y - halfLineWidth), 
			rect_size - Vector2(halfLineWidth, halfLineWidth), Vector2(rect_size.x - halfLineWidth, halfLineWidth)]
	draw_polyline(points, lineColor, lineWidth)
	if blockLen >= 1.0:
		draw_polyline(points, blockColor, lineWidth)
	elif blockLen > 0.0:
		var frontValue = blockPos + blockLen * 0.5
		frontValue -= floor(frontValue)
		var frontPos = _ratio_to_pos(frontValue)
		var frontEdge = 0
		for i in pointRatios.size():
			if frontValue < pointRatios[i]:
				frontEdge = i
				break
		
		
		var backValue = blockPos - blockLen * 0.5
		backValue -= floor(backValue)
		var backPos = _ratio_to_pos(backValue)
		var backEdge = 0
		for i in pointRatios.size():
			if backValue < pointRatios[i]:
				backEdge = i
				break
		
#		print("frontPos = ", str(frontPos), " frontEdge = ", str(frontEdge), " frontValue = ", str(frontValue), " backPos = ", str(backPos), " backEdge = ", str(backEdge), " backValue = ", str(backValue))
		var drawPoints = [ backPos, frontPos ]
		if frontEdge == backEdge && blockLen > wRatio + hRatio:
			var i = frontEdge
			for j in 4:
				drawPoints.insert(j + 1, points[i])
				i = (i + 1) % 4
		elif frontEdge != backEdge:
			if frontEdge > backEdge:
				for i in frontEdge - backEdge:
					drawPoints.insert(i + 1, points[backEdge + i])
			elif frontEdge == 0 && backEdge == 3:
				drawPoints.insert(1, points[3])
			else:
				for i in backEdge - frontEdge:
					drawPoints.insert(i + 1, points[(backEdge + i) % 4])
		
		draw_polyline(drawPoints, blockColor, lineWidth)

func set_line_width(p_value):
	p_value = max(p_value, 0.01)
	if lineWidth == p_value:
		return
	
	lineWidth = p_value
	perimeterDirty = true
	update()

func _set(p_property:String, p_value):
	if p_property == "lineWidth":
		self.lineWidth = p_value
		return true
	
	return false

func _get(p_property:String):
	if p_property == "lineWidth":
		return lineWidth
	
	return null

func set_line_color(p_value):
	lineColor = p_value
	update()

func set_block_color(p_value):
	blockColor = p_value
	update()

func set_block_pos(p_value):
	p_value = clamp(p_value, 0.0, 1.0)
	if blockPos == p_value:
		return
	
	blockPos = p_value
	update()

func set_block_len(p_value):
	p_value = clamp(p_value, 0.0, 1.0)
	if blockLen == p_value:
		return
	
	blockLen = p_value
	update()

func _get_property_list():
	var ret = []
	ret.append({ "name":"lineWidth", "type":TYPE_REAL, "hint":PROPERTY_HINT_RANGE, "hint_string":"0.01, 10.0, 0.01, or_greater", "usage":PROPERTY_USAGE_DEFAULT })
	return ret

tool
extends Control

export var color := Color(0x067DED50)
export var hideColor := Color(0x067DED28)
export var hideTime := 0.2
export var showTime := 0.4

var time := 0.0

func _init():
	set_anchors_and_margins_preset(Control.PRESET_WIDE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(p_delta):
	time += p_delta
	var totalTime = showTime + hideTime
	if totalTime > 0 && time > totalTime:
		time -= totalTime * floor(time / totalTime)
	update()

func _draw():
	if time < showTime:
		draw_rect(Rect2(Vector2.ZERO, rect_size), hideColor.linear_interpolate(color, time/showTime))
	else:
		draw_rect(Rect2(Vector2.ZERO, rect_size), color.linear_interpolate(hideColor, (time - showTime)/hideTime))

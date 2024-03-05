extends ParallaxBackground

var portraitBg = preload("res://assets/images/portrait_bg.jpg")

# check viewport orientation
func _ready():
	Global.connect("orientationChange", self, "check_orientation")

# checks orientation, updates it
# and the view if it changes the mode
func check_orientation(isPortrait: bool, layoutChanged: bool):
	if layoutChanged:
		get_tree().reload_current_scene()


# listens to double click event to minimize
# game on desktop platforms
func minimize_game(event: InputEvent):
	if OS.has_feature("mobile"):
		return
	else:
		if event is InputEventMouseButton and \
		event.doubleclick and \
		event.button_index == BUTTON_LEFT and \
		Global.SettingsManager.getDoubleClickMinimizes():
			OS.window_minimized = true

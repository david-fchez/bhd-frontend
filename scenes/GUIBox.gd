extends CanvasLayer
# Called when the node enters the scene tree for the first time.
var glassBox: Node
var _balls : Array = []
var lastScoreUpdate: int = 0
var firstScore: bool = false

func _input(event):
	if event is InputEventMouseButton and \
	event.doubleclick and \
	event.button_index == BUTTON_LEFT and \
	Global.SettingsManager.getDoubleClickMinimizes():
		OS.window_minimized = true

func _ready():
	lastScoreUpdate = Engine.get_physics_frames()
	glassBox = get_tree().get_root().find_node("GlassBox", true, false)
	connect_to_signals()
	$VBoxContainer/ScoreLabel.text = Global.Game._playersBox.Name
	pass


func _process(delta):
	$Label.text = "FPS: " + str(Engine.get_frames_per_second())
	
	if !firstScore or (Engine.get_physics_frames() - self.lastScoreUpdate) >= 60:
		lastScoreUpdate = Engine.get_physics_frames()
		if !firstScore:
			firstScore = true
		_balls = []
		
		var playerActive = false
		var maxScale = 0
		
		for child in glassBox.get_children():
			if "Ball" in child.name:
				_balls.append(child)
				
				var b = child as RigidBody
				if b.scale.x > maxScale:
					maxScale = b.scale.x
				
				# check if player alive
				if child.guid == Global.PlayerInfo.PlayerId:
					playerActive = true
		
		_balls.sort_custom(self, "sortByScale")
		$VBoxContainer/ScoreValue.bbcode_text = ""
		var index: int = 1
		
		for ball in _balls:
			var ballName = Global.PlayerNicks.get(ball.guid) if Global.PlayerNicks.get(ball.guid) != null else ball.name
			
			# calculate health based on scale
			var health = round(range_lerp(ball.scale.x, 0.5, maxScale, 1, 100))
			
			if ball.guid == Global.PlayerInfo.PlayerId:
				ballName = "[color=#be1e2d]" + Global.PlayerInfo.Username + "[/color]"
			
			$VBoxContainer/ScoreValue.bbcode_text += str(index) + ". " +  ballName  \
			 + " (" + str(health)  + " HP)\r\n"
			
			index += 1
			if index > 10:
				break

		# display "finish" position if player has lost
		if !playerActive and not $VBoxContainer/ScoreResult.visible:
			$VBoxContainer/ScoreResult.visible = true
			var finishPlace = _balls.size() + 1
			$VBoxContainer/ScoreResult.text = "Placed as: " + str(finishPlace) + buildSuffix(finishPlace)


func sortByScale(a,b)->bool:
	return a.scale.x > b.scale.x

func _on_BackButton_pressed():
	Global.IsInGame = false
	Global.PlayerNicks.clear()
	Engine.set_time_scale(1.0)
	var res = get_tree().change_scene(Global.GameList)
	if res != 0:
		Global.GameState.ErrorOutput("Cant open scene")

# Connects to signals that update the box state
func connect_to_signals():
	Settings.connect("settingsOpen", self, "handleHud")
	
func handleHud(isOpen: bool):
	if isOpen:
		$BackButton.visible = false
		$StatusBar.visible = false
	else:
		$BackButton.visible = true
		$StatusBar.visible = true
	pass

func buildSuffix(place: int):
	match place:
		1:
			return "st"
		2:
			return "nd"
		3:
			return "rd"
		_:
			return "th"

extends Control

var boxInfo: BoxInfo
var valid_position: bool = false
var countdown: int
var rng = RandomNumberGenerator.new()
var portraitSize: Vector2
var thread: Thread

const glassBox = preload("res://scenes/GlassBoxPreview.tscn")

onready var countdownLabel = $Vbox/Grid/Vbox/CountdownLabel
onready	var viewport = $Vbox/Grid/Vbox/VBoxContainer/ViewportContainer

		
func _ready():
	Global.IsInGame = true
	portraitSize = Vector2(get_viewport().size.x, get_viewport().size.y)
	$Title.text = Global.Game._playersBox.Name
	check_orientation()
	get_box_data(Global.Game._playersBox)
	connect_to_signals()
	init_box_preview()


# if in portrait mode, build UI differently	
func check_orientation():
	if Global.IsPortrait:
		$Vbox/Grid.columns = 1
		$Vbox.rect_size = Vector2(portraitSize.x, portraitSize.y * 0.9) #90% to allow space for margins
		$Vbox.rect_position = Vector2(0,75) #space for title + centering
		$Vbox/Grid.rect_size = portraitSize
		$Vbox/Grid/Vbox.set_h_size_flags(SIZE_EXPAND_FILL) #expand to fill
		$Vbox/Grid/Vbox/VBoxContainer/Sprite.position = Vector2(portraitSize.x / 2, 257) #sprite does not expand, so move it
		$Vbox/Grid/Hbox3.add_constant_override("separation", 10) #smaller spacing


# Get box data and fill info
func get_box_data(box: BoxInfo = null):
	# only update if boxes match
	if Global.Game._playersBox.BoxId == box.BoxId:
		boxInfo = box
		if boxInfo != null:
			# update labels
			$Vbox/Grid/Hbox3/PlayerLabel.text = "Players: " + str(boxInfo.PlayerCount) + "/" + str(boxInfo.MaxPlayerCount)
			$Vbox/Grid/Hbox3/RewardLabel.text = "Reward: " + Global.Wallet.displayCurrency(boxInfo.Reward)
			$Vbox/Grid/Hbox3/StatusLabel.text = "Status: " + BoxInfo.parse_status(boxInfo.Status)	
			$Vbox/Grid/Hbox3/VoteCountLabel.text = "Speed-up votes: " + str(boxInfo.SpeedupVoteCount) + "/" + str(boxInfo.PlayerCount)	
			
			
			# in warmup status, start countdown
			if boxInfo.Status == BoxInfo.BoxStatusWarmup and $Timer.time_left == 0:
				start_timer(boxInfo)


# when entering warmup status, start timer
# and show speedup button
func start_timer(box: BoxInfo):
	countdown = box.WarmupCountdown + 30
	$Timer.start()
	$Vbox/Grid/Hbox3/Hbox2/VoteButton.visible = true
	$Vbox/Grid/Hbox3/VoteCountLabel.visible = true

# update remaining countdown state, and
# update final box settings on timeout
func _on_Timer_timeout():
	if countdown > 1:
		countdown -= 1
		countdownLabel.text = "Starting in:\n" + str(countdown) + " s"
		countdownLabel.show()
	else:
		update_box_settings()
		$Timer.stop()
		countdownLabel.text = "Starting now!"


# Connects to signals that update the state
func connect_to_signals():
	Global.Game.connect("onBoxClose", self, "get_box_data")
	Global.Game.connect("onBoxDelete", self, "get_box_data")
	Global.Game.connect("onBoxUpdate", self, "get_box_data")
	Global.Game.connect("onPhysicsFileDelivery", self, "handle_file")
	Global.Game.connect("onBoxSpeedup", self, "speed_up")
	Global.Game.connect("onBoxPlayerListUpdate", self, "update_players")
	ConfirmDialog.connect("popup_hide", self, "handle_confirmation")
	$StatusBar.connect("currencyChanged", self, "change_currency")


# updates player nick list
func update_players(req: BoxPlayerListUpdateRequest):
	if req.BoxId == boxInfo.BoxId:
		for player in req.Players.asArray():
			# insert into dictionary of pIDs and usernames
			Global.PlayerNicks[player.PlayerId] = player.Username


# speeds up the countdown for simulation playout
func speed_up(boxId: String, secondsToSpeedUp: int):
	if boxId == boxInfo.BoxId:
		print("Speeding up: " + str(countdown) + " - " + str(secondsToSpeedUp))
		countdown -= secondsToSpeedUp


# update currency displaying
func change_currency():
	$Vbox/Grid/Hbox3/RewardLabel.text = "Reward: " + Global.Wallet.displayCurrency(boxInfo.Reward)


# handle physics file for simulation
func handle_file(box: BoxInfo):
	LoadingDialog.popup_centered()
	get_box_data(box)
	var newGame = box_game.new(0).to_box_game(boxInfo.PhysicsData)
	Global.LastBoxGame = newGame
	var res = get_tree().change_scene(Global.ReplayBox)

# Shows the box preview in a viewport
func init_box_preview():
	var txtr = $Vbox/Grid/Vbox/VBoxContainer/ViewportContainer.get_texture()
	$Vbox/Grid/Vbox/VBoxContainer/Sprite.texture = txtr


# show the confirmation dialog
func _on_CancelButton_pressed():
	ConfirmDialog.confirmationMessage = "Are you sure you want to exit?"
	ConfirmDialog.popup_centered()
	
# calls the cancellation logic if confirmed
func handle_confirmation():
	# to prevent unexpected behaviour
	if ConfirmDialog.isQuitConfirmation:
		return
		
	if ConfirmDialog.confirmed:
		Global.IsInGame = false
		Global.Game.exitBox()
		get_tree().change_scene(Global.GameList)	

# Updates the box settings
func update_box_settings():
	# randomize power
	rng.randomize()
	var pwr = rng.randi_range(1, 100)
	
	var instance = $Vbox/Grid/Vbox/VBoxContainer/ViewportContainer/GlassBoxPreview

	# call BC to update box settings
	var normalized = instance.getDirection()
	var boxSettings	= PlayerBoxSettings.new()
	boxSettings.BallPower = pwr
	boxSettings.X = normalized.x
	boxSettings.Y = normalized.y
	boxSettings.Z = normalized.z
	var response = Global.Game.updateBoxSettings(boxInfo.BoxId, boxSettings)
	
	# empty string on success
	if response == "":
		pass
	else:
		Global.GameState.ErrorOutput(response)


# update slider value preview
func _on_Power_value_changed(value):
	$Vbox/Grid/Vbox/Vbox2/SliderValue.text = str(value)


# when viewport gets mouse input, allow change
func _on_VBoxContainer_gui_input(event):
	viewport.set_physics_object_picking(true)
	viewport.unhandled_input(event)


# call vote for game speed up logic
func _on_VoteButton_pressed():
	if boxInfo != null:
		LoadingDialog.popup_centered()
		call_api()

# Call BC
func call_api():
	thread = Thread.new()
	thread.start(self, "_vote_speedup")
	
# call bc to speed up
func _vote_speedup(data):
	# call BC
	var response = Global.Game.voteForBoxSpeedup(boxInfo.BoxId)
	
	call_deferred("handle_thread_work")
	return response

# Wait for thread completion
func handle_thread_work():
	var response = thread.wait_to_finish()
	LoadingDialog.hide()	
	
	# empty string on success
	if response == "":
		$Vbox/Grid/Hbox3/Hbox2/VoteButton.disabled = true
		$Vbox/Grid/Hbox3/Hbox2/VoteButton.text = "Vote sent!"
	else:
		Global.GameState.ErrorOutput(response)



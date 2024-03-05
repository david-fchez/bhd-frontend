extends CanvasLayer

var sphereGame: Node
var sphereInfo: SphereInfo = null
var joinResponse : SphereJoinResponse = null
var enterResponse : SphereEnterResponse = null
var rng = RandomNumberGenerator.new()

var isJoinAction : bool = true
var isInEndgame: bool = false

var rngArray = []

# Called when the node enters the scene tree for the first time.
func _ready():
	sphereGame = get_tree().get_root().find_node("SphereGame", true, false)
	sphereInfo = Global.Game.getSphereInfo()
	updateSphereStats()
	connect_to_signals()
	pass
	


#show FPS counter
func _process(delta):
	$Control/Label.text = "FPS: " + str(Engine.get_frames_per_second())

#update the sphere stats in the gui overlay
func updateSphereStats()->void:
	$Control/Multi/EntryFeeValue.text = Global.Wallet.displayCurrency(sphereInfo.EntryFee * $Control/Multi/Multiplier.value)
	$Control/Stats/RewardLabel.text = "Jackpot: " + Global.Wallet.displayCurrency(sphereInfo.Reward)
	#$Stats/StatusLabel.text = "Status: " + SphereInfo.parse_status(sphereInfo.Status)

# callback for the onSphereUpdate signal
func sphereUpdate(sphereInfo: SphereInfo = null)->void:
	self.sphereInfo = sphereInfo
	updateSphereStats()
	pass

#sphere exit, returns to the main menu
func _on_BackButton_pressed():
	Engine.set_time_scale(1.0)
	
	var res
	if isInEndgame:
		res = get_tree().reload_current_scene()
	else:
		Global.IsInGame = false
		res = get_tree().change_scene(Global.MainMenu)
		
	if res != 0:
		Global.GameState.ErrorOutput("Cant open scene")


# Connects to signals that update the sphere state
func connect_to_signals():
	Settings.connect("settingsOpen", self, "handleHud")
	Global.Game.connect("onSphereUpdate", self, "sphereUpdate")
	ConfirmDialog.connect("popup_hide", self, "handle_confirmation")
	ConfirmDialog.connect("about_to_show", self, "handleHud", [true])
	ErrorDialog.connect("popup_hide", self, "handleHud", [false])
	$Control/StatusBar.connect("currencyChanged", self, "updateSphereStats")

#handle join and enter sphere confirmation dialog results
func handle_confirmation():
	if not ConfirmDialog.confirmed:
		handleHud(false)
		
	if ConfirmDialog.isQuitConfirmation:
		return
		
	if ConfirmDialog.confirmed and isJoinAction:
		joinSphereCall()
	else:
		handleHud(false)

#hides the gui HUD overlay when a dialog is open
func handleHud(isOpen: bool):
	if isOpen:
		self.visible = false
	else:
		self.visible = true
	pass

func handleHudForEndGame():
	self.visible = true
	$Control/BackButton.visible = true
	$Control/StatusBar.visible = true
	$Control/Hbox/JoinSphere.visible = false
	$Control/Stats.visible = false
	$Control/Multi.visible = false

#call backend join sphere method after the player clicked Confirm in the dialog
func joinSphereCall():
	joinResponse = Global.Game.joinSphere(self.sphereInfo.SphereId, $Control/Multi/Multiplier.value)
	if joinResponse != null:
		$Control/Hbox/JoinSphere.visible = false
		enterSphereCall()
	else:
		$Control/Hbox/JoinSphere.visible = true

#call backend enter sphere method after player sets power and clicks fire button
func enterSphereCall():
	var signedTx = Global.Wallet.signTransaction(joinResponse.Transaction)
	if signedTx != null:
		rng.randomize()
		rngArray = []
		for bullet in $Control/Multi/Multiplier.value:
			self.rngArray.append(_checkIfRngInArray(_generateRandomNum()))
		self.enterResponse = Global.Game.enterSphere(self.sphereInfo.SphereId, self.rngArray,  signedTx)
	if self.enterResponse != null:
		$Control/Hbox/JoinSphere.visible = false
		sphereGame.fireActionCall(self.enterResponse.IsWinner, $Control/Multi/Multiplier.value)
	else:
		$Control/Hbox/JoinSphere.visible = true


func _checkIfRngInArray(rndNum: String)->String:
	var exists : bool = true
	while(exists):
		if self.rngArray.find(rndNum) == -1:
			exists = false
		else:
			rndNum = _generateRandomNum()
	return rndNum

func _generateRandomNum()->String:
	rng.randomize()
	return str(rng.randi_range(1,21000000))


#handle join button click logic
func _on_JoinSphere_pressed():
	handleHud(true)
	var text = "You are about to join the sphere game. The fee is [color=white] %s SAT[/color]. Confirm?"
	var formattedMsg = text % [str(self.sphereInfo.EntryFee * $Control/Multi/Multiplier.value)]
	ConfirmDialog.confirmationMessage = formattedMsg
	ConfirmDialog.popup_centered()

func endGameScreen():
	isInEndgame = true
	handleHudForEndGame()
	GameResult.request = null
	GameResult.isWinner = self.enterResponse.IsWinner
	yield(get_tree().create_timer(2), "timeout")
	GameResult.popup_centered()


func _on_Multiplier_value_changed(value):
	$Control/Multi/MultiValue.text = str(value)
	$Control/Multi/EntryFeeValue.text = Global.Wallet.displayCurrency(sphereInfo.EntryFee * $Control/Multi/Multiplier.value)


func _on_Control_gui_input(event):
	if OS.has_feature("mobile"):
		return
	else:
		if event is InputEventMouseButton and \
		event.doubleclick and \
		event.button_index == BUTTON_LEFT and \
		Global.SettingsManager.getDoubleClickMinimizes():
			OS.window_minimized = true

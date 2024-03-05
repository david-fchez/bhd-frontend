extends Control

var greenLight: String = "res://assets/images/green_light.png"
var redLight: String = "res://assets/images/red_light.png"

onready var balanceLabel = $VBoxContainer/HBoxContainer/BalanceLabel

var balance: GetBalanceResponse

signal currencyChanged(isBCH) # emits when currency changes between SAT/BCH

func _ready():
	# Check one-shot as well
	connect_to_signals()
	check_data()
	hide_quit()
	ConfirmDialog.connect("popup_hide", self, "handle_confirmation")


# hide quit on mobile platforms
func hide_quit():
	if OS.has_feature("mobile"):
		$QuitBtn.hide()
		

# connect to signals to update icon
func connect_to_signals():
	Global.Api.getTcpClient().connect("onConnect",self,"update_sync_icon", [greenLight])
	Global.Api.getTcpClient().connect("onDisconnect",self,"update_sync_icon", [redLight])
	
	# present across many scenes to notify the player about result
	# connect to theese signals in StatusBar since it is
	Global.Game.connect("onPlayerLoose", self, "show_result", [false])
	Global.Game.connect("onPlayerWon", self, "show_result", [true])


# show winner or loser popup
# request is typeof BoxShowWinnerRequest or BoxShowLooserRequest
func show_result(request, isWinner: bool): 
	
	# different info display if ingame or on other screens
	if Global.IsInGame:	
		# 1s pause to let user see game has ended
		yield(get_tree().create_timer(1.0), "timeout")
		
		GameResult.request = request
		GameResult.isWinner = isWinner
		GameResult.popup_centered()
	else:
		SnackBar.add_snack(request)
		SnackBar.show()


# Checks data to update the balance
func check_data():
	if Global.Wallet:
		balance = Global.Wallet.getBalance([Global.PlayerInfo.BchAddress])
		if balance != null:
			if Global.ShowBCH:
				balanceLabel.text = str(balance.BalanceBch) + " BCH"
			else:
				balanceLabel.text = str(balance.BalanceSat) + " SAT"
			
		else:
			balanceLabel.text = "-,---"	
			


# Every x secs, check for fresh data
func getData():
	check_data()

# updates the icon w passed resource (img path)
func update_sync_icon(resource: String):
	$SyncTexture.texture = load(resource)


func _on_SettingsButton_pressed():
	Settings.popup_centered()


# on click or tap event, change currency
func _on_BalanceLabel_gui_input(event):
	if (event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT) \
	or (event is InputEventScreenTouch and event.is_pressed()):
		Global.ShowBCH = !Global.ShowBCH
		emit_signal("currencyChanged")
		check_data()



func _on_QuitBtn_pressed():
	ConfirmDialog.isQuitConfirmation = true
	ConfirmDialog.confirmationMessage = "Are you sure you want to quit?"
	ConfirmDialog.popup_centered()


# calls the cancellation logic if confirmed
func handle_confirmation():
	# if quit in msg, it means quit game dialog is raised
	if ConfirmDialog.confirmed and ConfirmDialog.isQuitConfirmation:
		get_tree().quit()
	else:
		ConfirmDialog.isQuitConfirmation = false


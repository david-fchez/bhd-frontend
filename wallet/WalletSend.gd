extends Control

onready var receiverField = $VBox/CC1/VBox/ReceiverField
onready var amountField = $VBox/CC2/VBox/AmountField

var balance: GetBalanceResponse
var thread: Thread

func _ready():
	get_current_balance()
	ConfirmDialog.connect("popup_hide", self, "handle_confirmation")
	scale_ui()
	

func scale_ui():
	if Global.IsPortrait:
		$VBox.rect_scale = Vector2(1, 1.2)
		$VBox.add_constant_override("separation", 100)

func _on_CancelButton_pressed():
	get_tree().change_scene(Global.MainMenu)


# check and execute transfer
func _on_ConfirmButton_pressed():
	if receiverField.text == "" || amountField.text == "":
		show_error("All fields are required")
		return
	
	var text = "Confirm the transfer of [color=white] %s SAT[/color] to address %s?"
	var formattedMsg = text % [amountField.text, receiverField.text]
	ConfirmDialog.confirmationMessage = formattedMsg
	ConfirmDialog.popup_centered()

# handle ConfirmDialog cases
func handle_confirmation():
	if ConfirmDialog.isQuitConfirmation:
		return
	
	if ConfirmDialog.confirmed:
		LoadingDialog.popup_centered()
		call_api()

# Call BC
func call_api():
	thread = Thread.new()
	thread.start(self, "_transfer_coins")
	
# Init coin transfer
func _transfer_coins(data):
	# call BC
	var response = Global.Wallet.sendCoins(Global.PlayerInfo.BchAddress, receiverField.text, int(amountField.text))
	
	call_deferred("handle_thread_work")
	return response

# Wait for thread completion
func handle_thread_work():
	var response = thread.wait_to_finish()
	LoadingDialog.hide()	
	
	# null or string indicates error, otherwise success if Tx type
	if response == null:
		pass
	elif typeof(response) == TYPE_STRING:
		Global.GameState.ErrorOutput(response)
	elif response.get_class() == "Tx":
		InfoDialog.message = "Coin transfer successful"
		InfoDialog.popup_centered()
		#_on_CancelButton_pressed() # navigate
	
	
func show_error(error: String):
	Global.GameState.ErrorOutput(error)


func get_current_balance():
	if Global.Wallet != null:
		balance = Global.Wallet.getBalance([Global.PlayerInfo.BchAddress])
		if balance != null:
			if balance.BalanceBch < 0.01:
				$VBox/HBox/BalanceLabel.text = str(balance.BalanceSat) + " SAT"
			else:
				$VBox/HBox/BalanceLabel.text = str(balance.BalanceBch) + " BCH"
		else:
			$VBox/HBox/BalanceLabel.text = "?.??"	
		 

# Fills the amount field when a button (0.25, 0.5...) is pressed
func fill_amount(percentage: float):
	if balance != null:
		if Global.ShowBCH:
			$VBox/CC2/VBox/AmountField.text = str(balance.BalanceBch * percentage) + " BCH"
		else:
			$VBox/CC2/VBox/AmountField.text = str(balance.BalanceSat * percentage) + " SAT"

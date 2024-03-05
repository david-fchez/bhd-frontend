extends Control

onready var pwdField = $Vbox/PasswordContainer/VBoxContainer/Password

var mnemonic: String

func _ready():
	$Vbox/PasswordContainer/VBoxContainer/Password.grab_focus()

func validate_pwd() -> bool:
	return Global.PlayerInfo.isPasswordValid(pwdField.text)


# check pwd, if valid get mnemonic and show it
func _on_Confirm_pressed():
	if validate_pwd():
		mnemonic = Global.Wallet.getWaletMnemonic()
		$Vbox/PasswordContainer.hide()
		$Vbox/MnemonicContainer/Mnemonic.text = mnemonic
		$Vbox/MnemonicContainer.show()
		$Vbox/CenterContainer/Confirm.hide()
		$Vbox/CenterContainer/Copy.show()
		$Vbox.add_constant_override("separation", 90)
	else:
		Global.GameState.ErrorOutput("Incorrect password")


func _on_Back_pressed():
	get_tree().change_scene(Global.PreviousScene)

# copy to clipboard and show Copied!
func _on_Copy_pressed():
	$CopiedLabel.show()
	OS.set_clipboard($Vbox/MnemonicContainer/Mnemonic.text)
	yield(get_tree().create_timer(1.0), "timeout")
	$CopiedLabel.hide()

# on Enter press, confirm
func _on_Password_text_entered(new_text):
	_on_Confirm_pressed()

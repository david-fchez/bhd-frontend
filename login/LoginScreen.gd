extends Node

var isFirstRun = true
var thread: Thread

onready var usernameField = $HBoxContainer/InputContainer/UsernameContainer/VBoxContainer/Username
onready var pwdField = $HBoxContainer/InputContainer/PasswordContainer/VBoxContainer/Password
onready var repeatedPwdField = $HBoxContainer/InputContainer/RepeatedPwdContainer/VBoxContainer/RepeatedPwd
onready var button = $HBoxContainer/InputContainer/ButtonContainer/Button
onready var usernameLabel = $HBoxContainer/InputContainer/UsernameContainer/VBoxContainer/UsernameLabel
onready var repeatedPwdContainer = $HBoxContainer/InputContainer/RepeatedPwdContainer


func _ready():
	Global.LoginControls = $HBoxContainer
	check_player_config()
	focus_field()
	check_settings_file()
	ConfirmDialog.connect("popup_hide", self, "handle_confirmation")
	hide_quit()
	scale_ui()


func scale_ui():
	if Global.IsPortrait:
		$HBoxContainer.rect_scale = Vector2(1, 1.2)
	else:
		$HBoxContainer.rect_scale = Vector2(1, 1)

# hide quit on mobile platforms
func hide_quit():
	if OS.has_feature("mobile"):
		$QuitBtn.hide()

# listen if 'Enter' is pressed to
# trigger Login/Register button
# if repeatedPwd entered, bool arg is true
func enter_pressed(text, repeatedPwd: bool):
	if (isFirstRun and repeatedPwd) or (!isFirstRun and !repeatedPwd):
		_on_Button_pressed() # validate login
	else:
		repeatedPwdField.grab_focus() # else focus next field

# Check if user has played before to show only the password prompt
func check_player_config():
	# check if this is first run
	self.isFirstRun = Global.PlayerInfo.IsReqistrationRequired()
	# Show/hide needed fields
	if Global.PlayerInfo.Username != "":
		button.text = "Login"
		$HBoxContainer/InputContainer/UsernameContainer/VBoxContainer/Label.hide()
		usernameField.hide()
		usernameLabel.show()
		usernameLabel.text = Global.PlayerInfo.Username
		repeatedPwdContainer.hide()


func focus_field():
	if isFirstRun:
		usernameField.grab_focus()
	else:
		pwdField.grab_focus()

func validate_repeated_pwd() -> bool:
	return pwdField.text == repeatedPwdField.text

func validate_fields() -> bool:
	return pwdField.text != "" and repeatedPwdField.text != "" and usernameField.text != ""

func validate_pwd() -> bool:
	return Global.PlayerInfo.isPasswordValid(pwdField.text)
	
func validate_pwd_length() -> bool:
	return pwdField.text.length() >= 6
	
func validate_username() -> bool:
	return usernameField.text.length() >= 4 and usernameField.text.length() <= 16


func _on_Button_pressed():
	if form_valid():
		#$AudioStreamPlayer.play()
		login()
	elif !validate_fields() and isFirstRun:
		show_error("All fields are required")
	elif !validate_repeated_pwd() and isFirstRun:
		show_error("Passwords don't match")
	elif !validate_pwd_length() and isFirstRun:
		show_error("Password needs to contain at least 6 characters")	
	elif !validate_username() and isFirstRun:
		show_error("Username needs to contain at least 4 characters and at most 16 characters")
	elif !validate_pwd() and !isFirstRun:
		pwdField.grab_focus()
		show_error("Incorrect password")


func show_error(errorString: String):
	Global.GameState.ErrorOutput(errorString)

# Validate form depending on whether it's registration or login logic	
func form_valid() -> bool:
	return (isFirstRun and validate_fields() and validate_repeated_pwd() and validate_pwd_length() and validate_username()) or (!isFirstRun and validate_pwd())


func login():
	# create new user or validate the 
	# password	
	if Global.PlayerInfo.IsReqistrationRequired():
		Global.PlayerInfo.newPlayer(usernameField.text, pwdField.text)
		
	if Global.PlayerInfo.isPasswordValid(pwdField.text):
		$HBoxContainer.hide()
		LoadingDialog.popup_centered()
		call_api()

# Call additional initialization after login
func call_api():
	thread = Thread.new()
	thread.start(self, "_init_backend")
	
# Init data on newly created thread
func _init_backend(data):
	var response = Global.GameState.init_after_login()
	call_deferred("handle_thread_work")
	return response

# Wait for thread completion
func handle_thread_work():
	var request = thread.wait_to_finish()
	LoadingDialog.hide()	
	$HBoxContainer.show()
	go_to_main_menu()

# try to register the address and navigate to main
# menu if registration is passed
func go_to_main_menu():
	var registerAddressReq = Global.Wallet.registerAddress(Global.PlayerInfo.BchAddress)
	if registerAddressReq != "":
		Global.GameState.ErrorOutput(registerAddressReq)
		return
		
	var res = get_tree().change_scene(Global.MainMenu)
	if res != 0:
		Global.GameState.ErrorOutput("Cant open scene")

# will check the settings file
# and set the audio levels
func check_settings_file():
	var muted = Global.SettingsManager.getVolumeMuted()
	if muted:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)
	else:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), Global.SettingsManager.parse_audio_level(Global.SettingsManager.getMasterVolume()))


func _on_QuitBtn_pressed():
	ConfirmDialog.isQuitConfirmation = true
	ConfirmDialog.confirmationMessage = "Are you sure you want to quit?"
	ConfirmDialog.popup_centered()


# calls the cancellation logic if confirmed
func handle_confirmation():
	if ConfirmDialog.confirmed and ConfirmDialog.isQuitConfirmation:
		get_tree().quit()
	else:
		ConfirmDialog.isQuitConfirmation = false

# on enter, focus pwd
func _on_Username_text_entered(new_text):
	pwdField.grab_focus()

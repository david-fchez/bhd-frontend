extends Popup

var mutedAudio = preload("res://assets/images/sound-off.png")
var enabledAudio = preload("res://assets/images/sound-on.png")
var hoverMuted = preload("res://assets/images/sound-off-hover.png")
var hoverEnabled = preload("res://assets/images/sound-on-hover.png")
var muted: bool = false

onready var audioTexture = $Vbox/Hbox2/AudioTexture

var isOpen :bool = false
signal settingsOpen(isOpen)


# on init dialog, update settings according to file
func _on_Settings_about_to_show():
	self.isOpen = true
	emit_signal("settingsOpen", self.isOpen)
	
	show_controls()
	
	store_scene()
	
	scale_ui()
	
	$Vbox/Hbox/Username.text = Global.PlayerInfo.Username
	muted = Global.SettingsManager.getVolumeMuted()
	if muted:
		mute_audio()
	else:
		unmute(Global.SettingsManager.getMasterVolume())
	
	$Vbox/Hbox8/CheckBtn.pressed = Global.SettingsManager.getAutoEnterBox()
	$Vbox/Hbox9/DblClickBtn.pressed = Global.SettingsManager.getDoubleClickMinimizes()
	
	# hide doubleclick minimize if on mobile
	if OS.has_feature("mobile"):
		$Vbox/Hbox9.hide()


func scale_ui():
	if Global.IsPortrait:
		rect_scale = Vector2(1, 1.2)

# will show the controls and separation
# depending on the in-game state
func show_controls():
	if Global.IsInGame:
		$Vbox/Hbox4.visible = false
		$Vbox/Hbox5.visible = false
		$Vbox/Hbox7.visible = false
		$Vbox.add_constant_override("separation", 60)
	else:
		$Vbox/Hbox4.visible = true
		$Vbox/Hbox5.visible = true
		$Vbox/Hbox7.visible = true
		$Vbox.add_constant_override("separation", 18)


# updates the counter text value
func _on_Audio_value_changed(value):
	$Vbox/Hbox3/CounterValue.text = str(round(value))
	if value == 0:
		mute_audio()
	else:
		unmute(value)


# mutes the audio and replaces textures
func mute_audio():
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	muted = true
	audioTexture.texture_normal = mutedAudio
	audioTexture.texture_hover = hoverMuted
	audioTexture.texture_pressed = mutedAudio
	$Vbox/Hbox3/CounterValue.text = str(0)
	$Vbox/Hbox3/Audio.set_value(0)


# unmutes the audio, sets volume value and replaces textures
func unmute(setVolume: float = 0):
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	
	# in dB (-60 (silent) to 0 (normal))
	var targetDb = -30 if setVolume == null else SettingsManager.parse_audio_level(setVolume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), targetDb)
	muted = false
	audioTexture.texture_normal = enabledAudio
	audioTexture.texture_hover = hoverEnabled
	audioTexture.texture_pressed = enabledAudio
	if setVolume > 0:
		$Vbox/Hbox3/CounterValue.text = str(round(setVolume))
		$Vbox/Hbox3/Audio.set_value(setVolume)


func _on_AudioTexture_pressed():
	if muted:
		unmute(50)
	else:
		mute_audio()


# save settings data on close press and 
# on popup_hide signal
func _on_BackButton_pressed():
	self.isOpen = false
	emit_signal("settingsOpen", self.isOpen)
	Global.SettingsManager.setMasterVolume($Vbox/Hbox3/Audio.value)
	Global.SettingsManager.setVolumeMuted(muted)
	hide()



func _on_TransactionList_pressed():
	hide()
	get_tree().change_scene(Global.TransactionList)


func _on_WalletInfo_pressed():
	hide()
	get_tree().change_scene(Global.WalletInfo)

# stores the scene in Global file
# but only in some cases where the
# navigation can be navigated back to
func store_scene():
	var currentScene = get_tree().get_current_scene().filename
	if Global.WalletInfo == currentScene or Global.TransactionList == currentScene:
		pass
	else:
		Global.PreviousScene = currentScene

# on toggle, update auto enter setting in file
func _on_CheckBtn_toggled(button_pressed):
	Global.SettingsManager.setAutoEnterBox(button_pressed)


# toggle double click minimizes
func _on_DblClickBtn_toggled(button_pressed):
	Global.SettingsManager.setDoubleClickMinimizes(button_pressed)

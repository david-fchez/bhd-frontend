extends Popup

export var confirmationMessage = ""

var isQuitConfirmation = false #set to true for quit confirm
var confirmed: bool

signal dialogResponse(confirmed)

func _ready():
	# the richtextlabel doesnt have
	# align properties so this is used
	$Bg/VBox/Text.set_use_bbcode(true)
	$Bg/VBox/Text.set_fit_content_height(true)
	
	confirmed = false

func _on_ConfirmDialog_about_to_show():
	$Bg/VBox/Text.bbcode_text = "[center]" + confirmationMessage + "[/center]"


func _on_Cancel_pressed():
	confirmed = false
	hide()

func _on_Confirm_pressed():
	confirmed = true
	hide()

# handle Esc press as cancel
func _input(event):
	if Input.is_action_pressed("ui_cancel"):
		_on_Cancel_pressed()

# Emit confirmation result
func _on_ConfirmDialog_popup_hide():
	emit_signal("dialogResponse", confirmed)

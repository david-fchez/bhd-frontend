extends Popup

export var message: String


func _on_CloseButton_pressed():
	hide()


func _on_InfoDialog_about_to_show():
	$Bg/VBox/Message.text = message

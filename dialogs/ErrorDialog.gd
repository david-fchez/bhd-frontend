extends Popup

export var errorString: String


func _on_CloseButton_pressed():
	hide()


func _on_ErrorDialog_about_to_show():
	$Bg/VBox/ErrorDetails.text = errorString

extends Popup

# Make UI not clickable when loading is happening
func _on_LoadingDialog_about_to_show():
	get_tree().get_root().set_disable_input(true)


# Make UI clickable after loading finishes
func _on_LoadingDialog_popup_hide():
	get_tree().get_root().set_disable_input(false)

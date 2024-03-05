extends Node

#onready var viewport = get_node("UiViewportContainer/UIViewport")

# Called when the node enters the scene tree for the first time.
func _ready():
	#print("Menu Frame: ", Engine.get_physics_frames())
	set_process_input(true)
	pass # Replace with function body.

func _process(delta):
	#if $Label.text != Global.InfoLabel:
	#	$Label.text = Global.InfoLabel
	pass


func _unhandled_input(event):
	pass
	#viewport.input(event)


# open link on press
func _on_CzfLink_meta_clicked(meta):
	OS.shell_open("http://playczf.com")

extends Node
class_name Main

var thread: Thread

# Load global data and start splash screen
# where game initialization is done
func _ready():
	#print("Main Frame: ", Engine.get_physics_frames())
	
	#set render resolution based on screen resolution
	var screenRes = OS.get_screen_size()
	ProjectSettings.set_setting("display/window/size/width", screenRes.x)
	ProjectSettings.set_setting("display/window/size/height", screenRes.y)
	
	show_splash_screen()

func show_splash_screen():
	var res = get_tree().change_scene(Global.SplashScreen)
	if res != 0:
		Global.GameState.ErrorOutput("Cant open scene")


extends Node

var thread: Thread

# Create new thread for BC init
func _ready():
	thread = Thread.new()
	thread.start(self, "_init_backend")

# Init GameState on newly created thread
func _init_backend(data):
	var game = load("res://scripts/GameState.gd").new()
	var response = game.init()
	call_deferred("handle_thread_work")
	return response

# Wait for thread completion
func handle_thread_work():
	var request = thread.wait_to_finish()
	# If initialization is already completed,
	# get the remaining animation time and
	# delay the navigation so it plays out
	var animationTimeLeft = $"../SplashAnimation".get_animation("DoSplashAnimation").length - $"../SplashAnimation".get_current_animation_position()
	if animationTimeLeft > 0:
		var timer = yield(get_tree().create_timer(animationTimeLeft), "timeout")
	
	finish_up()

func _on_SplashAnimation_animation_finished(_anim_name):	
	# If data's still initializing, show Loading...
	if thread.is_alive():
		$"../LoadingLabel".show()

# navigate to login
func finish_up():
	var res = get_tree().change_scene(Global.LoginScreen)
	if res != 0:
		Global.GameState.ErrorOutput("Cant open scene")


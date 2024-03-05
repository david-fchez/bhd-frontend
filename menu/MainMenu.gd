extends Control

# animations from AnimationPlayer node
const sphereAnimation = "scale_up_sphere"
const boxAnimation = "scale_up_box_game"
const sendAnimation = "scale_up_wallet_send"
const receiveAnimation = "scale_up_wallet_receive"

var navigateTo = ""

func _ready():
	# different layouts for different orientations
	if Global.IsPortrait:
		$Grid.show()
	else:
		$HBoxContainer.show()

func _on_Timer_timeout():
	get_tree().get_root().set_disable_input(false)
	get_tree().change_scene(navigateTo)

# Play navigation animation, disable input so other node 
# cant be selected and change scene
func start_navigation(animation: String, scene: String):
	$AudioStreamPlayer.play()
	get_tree().get_root().set_disable_input(true)
	$AnimationPlayer.play(animation)
	navigateTo = scene
	$Timer.start()


func _on_WalletSendButton_pressed():
	start_navigation(sendAnimation, Global.WalletSend)


func _on_SphereGameButton_pressed():
	start_navigation(sphereAnimation, Global.SphereGame)


func _on_WalletReceiveButton_pressed():
	start_navigation(receiveAnimation, Global.WalletReceive)

func _on_BoxGameButton_pressed():
	start_navigation(boxAnimation, Global.GameList)

func play_animation(animationName):
	#$AnimationPlayer.play(animationName)
	pass

# only used on sphere game click, to
# show loading dialog since it's 
# resource intensive
func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == sphereAnimation:
		LoadingDialog.popup_centered()

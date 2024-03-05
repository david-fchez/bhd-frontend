extends Spatial

onready var backgroundAudio = preload("res://assets/audio/gameplay/background_2.mp3")
onready var ballSphere = preload("res://scenes/Ball_for_sphere.tscn")
onready var explosion = preload("res://scenes/explosion/Explosion.tscn")

var didPlayerWin : bool = false
var ballCount : int = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	LoadingDialog.hide() # hide manually since it's set in MainMenu.tscn
	Global.IsInGame = true
	playBackgroundAudio()
	Global.connect("orientationChange", self, "checkCameraZoom")
	checkCameraZoom(Global.IsPortrait)
	pass # Replace with function body.

#rotate the enviorment and sphere in the scene
func _physics_process(delta):
		var current_y = $WorldEnvironment.environment.background_sky_rotation.y
		var current_x = $WorldEnvironment.environment.background_sky_rotation.x
		$WorldEnvironment.environment.background_sky_rotation.y = current_y + (0.0007)
		#$WorldEnvironment.environment.background_sky_rotation.x = current_x + (0.0005)
		if $SphereBody:
			var modelRotation: Vector2 = $SphereBody/TheSphere.get_surface_material(0).get_shader_param("MODEL_ROTATION")
			modelRotation.x += (0.002)
			modelRotation.y += (0.003)
			$SphereBody/TheSphere.get_surface_material(0).set_shader_param("MODEL_ROTATION",modelRotation)

#move camera further away from sphere if Android and portrait mode
func checkCameraZoom(isPortrait: bool, layoutChanged: bool = false)->void:
	var cameraPos = $CameraGimbal/InnerGimbal/Camera.get_translation()
	if OS.get_name() == "Android" and Global.IsPortrait:
		if(cameraPos.z <= 16.0):
			$CameraGimbal/InnerGimbal/Camera.set_translation(Vector3(0,0,40))
	elif OS.get_name() == "Android" and not Global.IsPortrait:
		if(cameraPos.z > 16.0):
			$CameraGimbal/InnerGimbal/Camera.set_translation(Vector3(0,0,15))
	pass

#start background audio playback
func playBackgroundAudio():
	var muted = Global.SettingsManager.getVolumeMuted()
	if muted:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)
	else:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), Global.SettingsManager.parse_audio_level(Global.SettingsManager.getMasterVolume()))
	
	$BackgroundAudioPlayer.set_stream(backgroundAudio)
	$BackgroundAudioPlayer.play()

#
const radius: float = 31.0
const sphereOrigin: Vector2 = Vector2(5,5)
const ballAccel: float = 18.0

#move the player ball into the sphere
func fireActionCall(isWin : bool, tryCount : int):
	self.didPlayerWin = isWin
	self.ballCount = tryCount
	if tryCount > 1:
		spawnBalls(tryCount)
	else:
		var ballItem = ballSphere.instance()
		var initPos : Vector3 = Vector3(radius,5,radius)
		ballItem.set_translation(initPos)
		add_child(ballItem, true)
		ballItem.linear_velocity = Vector3(-10,0,-10)
	pass

#spawn balls around the sphere, aim them towards
func spawnBalls(ballCnt: int)->void:
	var angle : float = 360.00 / ballCnt
	var currentAngle : float = angle
	
	for i in ballCnt:
		var x = (radius * cos(deg2rad(currentAngle))) + sphereOrigin.x
		var y = (radius * sin(deg2rad(currentAngle))) + sphereOrigin.y
		var ballItem = ballSphere.instance()
		var initPos : Vector3 = Vector3(x,5,y)
		ballItem.set_translation(initPos)
		
		#calc velocity and direction to sphere
		var direction = sphereOrigin - Vector2(x,y)
		var velocity = direction.normalized() * ballAccel
		ballItem.linear_velocity = Vector3(velocity.x, 0, velocity.y)
		
		add_child(ballItem, true)
		currentAngle += angle
		yield(get_tree().create_timer(0.3), "timeout")
	pass

var cnt : int = 0
#when the collision happens play win or lose scripted animation
#based on the didPlayerWin flag
#after the animation a dialog should apear
func _on_SphereBody_entered(body):
	body.get_node("CollisionShape").disabled = true
	
	var plasma = explosion.instance()
	plasma.set_translation(body.get_translation())
	plasma.scale = Vector3(3,3,3)
	add_child(plasma)
	plasma.emitEffect()
	cnt += 1
	
	if cnt >= self.ballCount:
		if self.didPlayerWin: 
			body.linear_velocity = Vector3(0,0,0)
			$SphereBody.queue_free()
			$SphereBody.visible = false
			body.set_translation(Vector3(5,5,5))
			body.scale = Vector3(8,8,8)
		
		$GuiOverlay.endGameScreen()

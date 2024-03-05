extends Spatial

onready var explosion = preload("res://scenes/explosion/Explosion.tscn")
onready var ballB = preload("res://scenes/Ball.tscn")
onready var ballR = preload("res://scenes/Ball_Player.tscn")

onready var backgroundAudio = preload("res://assets/audio/gameplay/background_1.mp3")

const maxSoundEffect : int  = 10
var soundCounter : int = 0

var thisBoxGame: box_game
var firstFrame: int
var ballCount: int
var currentBallCount: int

var velocityMultiplier : float = 0.3
var minVelocityThreshold: float = 2.0

var minScale 	:float = 0.5

var rng = RandomNumberGenerator.new()
func _ready():
	LoadingDialog.hide() # manually set in PreGame, so close here
	
	Global.IsInGame = true
	#firstFrame = Engine.get_physics_frames()
	rng.randomize()
	thisBoxGame = Global.LastBoxGame
	ballCount = thisBoxGame.playerCount
	self.currentBallCount = ballCount
	self.minScale = thisBoxGame.minScale
	
	#freeze the game physics
	Engine.set_time_scale(0.0)
	
	#spwan players in box
	spawnBalls(ballCount)
	# set the first frame
	firstFrame = Engine.get_physics_frames()
	
	#start background audio playback
	playBackgroundAudio()
	
	#unfreeze the game physics
	Engine.set_time_scale(1.0)
	Engine.set_iterations_per_second(60)

	pass


func _physics_process(delta):
		var current_y = $WorldEnvironment.environment.background_sky_rotation.y
		var current_x = $WorldEnvironment.environment.background_sky_rotation.x
		#$WorldEnvironment.environment.background_sky_rotation.y = current_y + (0.0007)
		#$WorldEnvironment.environment.background_sky_rotation.x = current_x + (0.0005)


func updateBallCount(newValue: int):
	currentBallCount = currentBallCount + newValue
	if currentBallCount <= 1:
		#stop the game, only 1 player left
		Engine.set_time_scale(1.0)
		#Engine.set_iterations_per_second(0)
		#var lastBall = get_tree().get_root().find_node("*Ball*", true, false)
		#lastBall.linear_velocity = Vector3(0,0,0)
		var errStr = Global.Game.clientDonePlaying()
		if errStr != "":
			Global.GameState.ErrorOutput(errStr)
		

func spawnEffect(isPlayer: bool, position: Vector3, scale: Vector3):
	var plasma = explosion.instance() #plasmaR.instance() if isPlayer else plasmaB.instance()
	plasma.set_translation(position)
	plasma.scale = scale
	add_child(plasma)
	plasma.emitEffect()

func spawnBalls(count: int)->void:	
	for item in thisBoxGame.balls:
		var isPlayer : bool = true if Global.PlayerInfo.PlayerId == item.guid else false
		var ballItem = ballR.instance() if isPlayer else ballB.instance()
		ballItem.isPlayer = isPlayer
		ballItem.isReplay = true
		ballItem.itemName = item.name
		ballItem.guid = item.guid
		ballItem.initPos = item.initPos
		ballItem.initVelocity = item.initVelocity
		ballItem.scale = Vector3(item.initScale, item.initScale, item.initScale)
		ballItem.set_translation(item.initPos)
		ballItem.events = item.positions
		add_child(ballItem, true)


func playBackgroundAudio():
	var muted = Global.SettingsManager.getVolumeMuted()
	if muted:
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)
	else:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), Global.SettingsManager.parse_audio_level(Global.SettingsManager.getMasterVolume()))
	
	$BackgroundAudioPlayer.set_stream(backgroundAudio)
	$BackgroundAudioPlayer.play()

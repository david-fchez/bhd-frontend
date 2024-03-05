extends Node

#this is the game state, it is global, use it to store game data
var GameState: GameState
#this holds the backend_wrapper from rust to godot, it is initialized in GameState when the game is fisrt started
#use it to directly interface with the backend
var PlayerInfo : PlayerInfo
var Api : ApiProxy
var Wallet : WalletClient
var Game : GameClient
var Log : ConsoleLog

var SettingsManager : SettingsManager

# Scene Locations - MUST be set MANUALLY
const Ball = "res://scenes/Ball.tscn"
const Player = "res://scenes/Ball_Player.tscn"
const PlasmaB = "res://scenes/Plasma.tscn"
const PlasmaR =  "res://scenes/Plasma_Red.tscn"
const ReplayBox = "res://scenes/ReplayGlassBox.tscn"
const MainMenu = "res://menu/menu.tscn"
const GameList = "res://scenes/GameList.tscn"
const SplashScreen = "res://splashscreen/splashscreen.tscn"
const PreGame = "res://scenes/PreGame.tscn"
const LoginScreen = "res://login/LoginScreen.tscn"
const TransactionList = "res://wallet/TransactionList.tscn"
const WalletSend = "res://wallet/WalletSend.tscn"
const WalletReceive = "res://wallet/WalletReceive.tscn"
const SettingsScreen = "res://scenes/Settings.tscn"
const SphereGame = "res://scenes/SphereGame.tscn"
const WalletInfo = "res://wallet/WalletInfo.tscn"

const BoxSize = Vector3(10,10,10)

var LastBoxGame: box_game

# contains a map of player id's and their
# nicknames to display in the box game simulation
var PlayerNicks: Dictionary = {}

# stores the previous scene filename, used to navigate back from some scenes
var PreviousScene: String

#Set to true when in box or sphere 3d secene
var IsInGame : bool = false

# true if the viewport is in portrait orientation (x < y)
var IsPortrait: bool 

# store the login control
var LoginControls: Control

func displayLoginControls(makeVisible: bool):
	LoginControls.show() if makeVisible else LoginControls.hide()

# show BCH or SAT currency
var ShowBCH: bool = false 

# array of boxIds that the player has joined to
var joinedBoxes: Array 


var project_size = Vector2(
		ProjectSettings.get_setting("display/window/size/width"),
		ProjectSettings.get_setting("display/window/size/height")
	)
var current_scale = -1

# enum which contains the
# values of the Tree columns
# it their corresponding order
enum TreeColumns {
	STATUS_SHORT,
	BOX_NAME,
	PLAYERS,
	STAKE,
	REWARD,
	NEW_ICON,
	CHECK_ICON
}


#orientationChange signal for mobile version
signal orientationChange(IsPortrait)


func _ready():
	OS.min_window_size = Vector2(project_size.x, project_size.y)
	_check_orientation()
	get_tree().connect("screen_resized", self, "_check_orientation")

# checks orientation, updates it
# and the view if it changes the mode
func _check_orientation():
	var screenRes = OS.get_screen_size()
	var isPortrait = screenRes.x < screenRes.y
	var layoutChanged = false
	
	if Global.IsPortrait != isPortrait:
		layoutChanged = true
	
	Global.IsPortrait = isPortrait
	emit_signal("orientationChange", isPortrait, layoutChanged)


# constantly check the scale and
# update the UI if needed
func _process(_delta: float) -> void:
	var new_scale = _calculate_interface_scale()
	if  new_scale != current_scale:
		get_tree().set_screen_stretch(
				SceneTree.STRETCH_MODE_DISABLED, \
				SceneTree.STRETCH_ASPECT_EXPAND, \
				Vector2.ZERO, \
				new_scale
		)
		current_scale = new_scale

# https://flashlight13.medium.com/here-is-my-story-about-multiple-resolutions-in-godot-336e72e8336c
# calculates scale for UI
func _calculate_interface_scale() -> int:
	var window_size = OS.get_window_size()
	
	var desired = min(project_size.x, project_size.y)
	var current = min(window_size.x, window_size.y)
	
	var scale = 1
	
	while current / scale > desired:
		scale += 1
	
	return max(scale - 1, 1) as int

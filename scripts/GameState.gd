extends Node
class_name GameState

# This init function will init the
# needed data before the login call
func init():
	Global.GameState = self
	Global.Log = ConsoleLog.new()
	Global.Log.setLogLevel(ConsoleLog.LogLevelDebug)
	
	#new instance of settings
	Global.SettingsManager = SettingsManager.new()
	
	# first load player info
	# if its not available
	# login will ask for username
	# and password repeat
	Global.PlayerInfo = PlayerInfo.new()
	if not Global.PlayerInfo.IsReqistrationRequired():
		Global.PlayerInfo.loadPlayerInfo()

# After the users logs in succeessfuly,
# call additional initializations
func init_after_login():
	
	# the connection to backend servers
	Global.Api = ApiProxy.new()
	Global.Api.start()
	
	# wallet functions
	Global.Wallet = WalletClient.new()
	Global.Wallet.start()
	
	# the functions handling game session
	Global.Game = GameClient.new(null)	
	Global.Game.start()
	Global.Game.updatePlayerInfo(Global.PlayerInfo)
	Global.PlayerInfo.save_wallet_data()
	
	# is api ready
	while true:
		if Global.Api.IsConnected:
			break
		else:
			OS.delay_msec(10)
	
	
#add global functions here
func ErrorOutput(error: String):
	# Pass error string, open dialog
	ErrorDialog.errorString = error
	ErrorDialog.popup_centered()
	print(error)


func testGlobalFunc():
	return "it works"




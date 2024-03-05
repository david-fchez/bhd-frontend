extends Node
class_name PlayerInfo

var Username : String
var PlayerId : String
var BchAddress : String
var Mnemonic : String
var HashedPassword : String
const configFileUri : String = "user://player_data.cfg"

# IsFirstRun returns true if this is first
# run for the player and he needs to set
# username and password
static func IsReqistrationRequired()->bool:
	var cf = ConfigFile.new()
	if cf.load(configFileUri) != OK:
		return true
	# TODO - return if needed?, can't get this info before wallet init and login is done
	#var walletMem = cf.get_value("Player","Mnemonic")
	#if walletMem == null or walletMem.empty():
		#return true
	return false

# loads player info from config file
func loadPlayerInfo()->void:
	var cf = ConfigFile.new()
	if cf.load(configFileUri) != OK:
		Global.GameState.ErrorOutput("Failed to retrive configuration")
		return
	self.Username = cf.get_value("Player","Username")		
	self.PlayerId = cf.get_value("Player","PlayerId")
	self.Mnemonic = cf.get_value("Player","Mnemonic")
	self.BchAddress = cf.get_value("Player","BchAddress")
	self.HashedPassword = cf.get_value("Player","Password")
	

# saves player info to config file
func savePlayerInfo()->void:
	var cf = ConfigFile.new()

	cf.set_value("Player","Username",self.Username)		
	cf.set_value("Player","PlayerId",self.PlayerId)
	cf.set_value("Player","Password",self.HashedPassword)
	cf.set_value("Player","Mnemonic",self.Mnemonic)
	cf.set_value("Player","BchAddress",self.BchAddress)
	cf.save(configFileUri)

# will create new player from username and 
# password
func newPlayer(username : String, password : String)->void:
	self.PlayerId = GuidUtils.v4() + "-01"
	self.Username = username
	self.HashedPassword = (password + ":" + username).sha256_text()
	self.savePlayerInfo()

# returns true if password matches one that
# we have stored in configuration file
func isPasswordValid(password : String)->bool:
	# check cfg file
	var file = ConfigFile.new()
	if file.load(configFileUri) != OK:
		Global.GameState.ErrorOutput("Failed to retrive configuration")
		return false
		
	var username = file.get_value("Player", "Username")
	var pwd = file.get_value("Player", "Password")
	if self.HashedPassword == "":
		self.HashedPassword = pwd
		
	return self.HashedPassword == ((password + ":" + username).sha256_text())

# saves specific wallet based data
# available after Wallet init and login
# only if this is a newly registered user
func save_wallet_data()->void:
	var cf = ConfigFile.new()
	if cf.load(configFileUri) != OK:
		Global.GameState.ErrorOutput("Failed to retrive configuration")
		return
		
	# if address exists dont overwrite but initialize wallet
	if cf.get_value("Player", "BchAddress") != "":
		Global.Wallet.initLocalWallet(cf.get_value("Player", "Mnemonic"))
		return
	
	# init wallet
	Global.Wallet.initLocalWallet("")
	self.Mnemonic = Global.Wallet.getWaletMnemonic()
	self.BchAddress = Global.Wallet.getWaletAddress()
		
	# need to save all values, otherwise they are lost
	cf.set_value("Player","Username",self.Username)		
	cf.set_value("Player","PlayerId",self.PlayerId)
	cf.set_value("Player","Password",self.HashedPassword)
	cf.set_value("Player","Mnemonic",self.Mnemonic)
	cf.set_value("Player","BchAddress",self.BchAddress)
	cf.save(configFileUri)
	

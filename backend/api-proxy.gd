extends Node
class_name ApiProxy

var _tcpClient : TcpClient
var _gameHost : String
var _gamePort : int
var _status : int = 0
var IsConnected : bool = false

# onApiErrorSignal fires an error
# when client should see the error
# signal onApiErrorSignal(msg)

func _init():
	pass
	
# will return the tcp client
# used to connect signals to	
func getTcpClient() -> TcpClient:
	return self._tcpClient

# will show error to the end user
func show_error(errorString: String):
	#emit_signal("onApiErrorSignal",errorString)
	
	# if loading, hide and show error
	if LoadingDialog.visible:
		LoadingDialog.hide()
	
	# show login controls
	Global.displayLoginControls(true)
	# use dialog from autoload, rather than
	# GameState since it may not be initialized	
	ErrorDialog.errorString = errorString
	ErrorDialog.popup_centered()


# starts the game client
# connects to server, first login
# then use the login response to 
# connect to actual game server
func start() -> void:
	self._initialize()
	
# perform initialization steps
func _initialize() -> void:
	var loginRes = self._login()
	
	if loginRes != "OK":
		# raise an error
		self.show_error("Cannot connect to BHD login server due to:" + loginRes)
		return
		
	# connect to the game server
	self._tcpClient = TcpClient.new(self._gameHost, self._gamePort)
	if self._tcpClient.connectToServer() != OK:
		self.show_error("Cannot connect to BHD login server")
		self.IsConnected = false
	else:
		self.IsConnected = true

# the purpose of login is to obtain
# the game server to be used for 
# handling game events	
func _login() -> String:
	var loginClient = TcpClient.new("api.bunnyhedger.com",10191)
	if loginClient.connectToServer() != OK:
		Global.displayLoginControls(true)
		return "no response from login server"
	var loginRequest = LoginRequest.new()
	loginRequest.Username = Global.PlayerInfo.Username
	loginRequest.Password = Global.PlayerInfo.HashedPassword
	var resp = loginClient.sendSyncRequest(loginRequest)
	loginClient.disconnectFromServer()
	if resp.IsSucessfull:
		if resp.PduType == BhdRequestTypes.BhdErrorResponseType:
			var obj = ErrorResponse.new()
			var errResponse = JsonHelper.json_string_to_class(resp.Payload,obj) as ErrorResponse
			return errResponse.Message
		else:
			var obj = LoginResponse.new()
			var loginResponse = JsonHelper.json_string_to_class(resp.Payload,obj) as LoginResponse
			if loginResponse.Info != "":
				return loginResponse.Info
			self._gameHost = loginResponse.Host
			self._gamePort = loginResponse.Port
		return "OK"
	return resp.ErrorInfo

# will send request toward server
# and return response or timeout
func SendRequest(obj:Object)->Object:
	return self._tcpClient.sendSyncRequest(obj)

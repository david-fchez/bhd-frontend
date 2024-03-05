extends Node
class_name WalletClient

func get_class():
	return "WalletClient"

func is_class(value):
	return value == "WalletClient"

# The backend interface via rust to golang.
# Implementation in golang signs the transaction
const _backendInterface = preload("res://backend.gdns")
var _localWallet = _backendInterface.new()
var _isUxtoListenerRegistered : bool = false
var _cachedGetBalanceResponse : GetBalanceResponse
var _isBalanceInfoDirty = true

# connect to tcp service signals
func start()->void:
	# connect to pdu signal, when pdu arrives
	# process the pdu if it is for game or wallet
	var ret = Global.Api.getTcpClient().connect("onRequestReceived",self,"onRequestReceived")
	if ret != OK:
		Global.GameState.ErrorOutput("Cannot connect wallet client to onRequestReceived signal on tcp client")
	# connect to reconnect signal, if reconnection occurs pull the
	# fresh info for wallet, boxes, sphere, etc.
	ret = Global.Api.getTcpClient().connect("onReconnect",self,"onReconnect")
	if ret != OK:
		Global.GameState.ErrorOutput("Cannot connect wallet client to onReconnect signal on tcp client")	
	
	
# extracts response from the local
# wallet implementation in golang	
func _toResult(data) -> LocalWalletResponse:
	return LocalWalletResponse.new(JSON.parse(data).result as Dictionary)	
	
# formats number into string with , separator
func formatNumberWithCommaSep(number):
	var string = str(number)
	var mod = string.length() % 3
	var res = ""

	for i in range(0, string.length()):
		if i != 0 && i % 3 == mod:
			res += ","
		res += string[i]

	return res

# returns the formatted currency
# depending on currently selected currency
# as a String. Expects the value in SAT
func displayCurrency(valueSAT: float)->String:
	# 0.01 BCH == 1 000 000 SAT
	if Global.ShowBCH:
		return str(float(valueSAT * 0.00000001)) + " BCH"
	else:
		return str(formatNumberWithCommaSep(valueSAT)) + " SAT"	


# will check the response and if it is 
# error response it will show error to the
# user.	
func isRequestSucessfull(r : PduContainer) -> bool:
	if r.PduType == BhdRequestTypes.BhdErrorResponseType:
		Global.Log.error("Got response with error:", r.PduId, r.PduType,r.Payload)
		var obj = ErrorResponse.new()
		var errResp = JsonHelper.json_string_to_class(r.Payload,obj) as ErrorResponse
		var msg = errResp.Message
		if msg.empty():msg = "No specific error!"
		Global.GameState.ErrorOutput(msg)
		return false
	return true
	
# handles the reconnection event
# when walet has update balance	
func onReconnect()-> void:
	Global.Log.debug("Reconnecting wallet client")
	self._isBalanceInfoDirty = true
	# force the new mempool filter
	self._isUxtoListenerRegistered = false
	
# handles requests from server
# this is normaly mempool transaction
# detected from the wallet so the
# client should call balance update
func onRequestReceived(req : PduContainer) -> void:
	if not isRequestSucessfull(req):return
	# handle the mempool filter request
	if req.PduType == BhdRequestTypes.BhdMemPoolTransactionRequestType:
		Global.Log.debug("Got request from server:", req.PduId, req.PduType,req.Payload)
		Global.Log.debug("Wallet balance is now dirty")
		self._isBalanceInfoDirty = true

# will instruct server to send mempool transaction
# and those	from the mined block to the client in order
# to update balance
func _registerMempoolFilter(addressList : Array):
	if self._isUxtoListenerRegistered : return
	var uxtoFilterRequest = MempoolFilterRequest.new(addressList)
	uxtoFilterRequest.PlayerId = Global.PlayerInfo.PlayerId
	var resp = Global.Api.SendRequest(uxtoFilterRequest)
	if isRequestSucessfull(resp):
		self._isUxtoListenerRegistered = true

# will register player bch address on server side
# so that transaction scanning can be fast and 
# efficient and ignore other address not involved
# with bhd game
func registerAddress(address : String)-> String:
	var request = RegisterRequest.new()
	request.BchAddress = address
	var resp = Global.Api.SendRequest(request)
	if isRequestSucessfull(resp):
		return ""
	return "Failed to register bch address"
	
# returns details about single transaction
# of interest to the caller
func getBalance(addressList : Array) -> GetBalanceResponse:
	# register mempool filter if not already
	self._registerMempoolFilter(addressList)
	self._isBalanceInfoDirty  = true
	if self._isBalanceInfoDirty == true || self._cachedGetBalanceResponse == null:
		var balanceRequest = GetBalanceRequest.new(addressList)
		balanceRequest.PlayerId = Global.PlayerInfo.PlayerId
		var resp = Global.Api.SendRequest(balanceRequest)
		if isRequestSucessfull(resp):
			var obj = GetBalanceResponse.new()
			var tx = JsonHelper.json_string_to_class(resp.Payload,obj) as GetBalanceResponse
			self._cachedGetBalanceResponse = tx
			self._isBalanceInfoDirty = false
			return tx
	return self._cachedGetBalanceResponse
	
func setMempoolFilter(addressList : Array)-> void:
	var memPoolFilterRequest = MempoolFilterRequest.new(addressList)
	var resp = Global.Api.SendRequest(memPoolFilterRequest)
	if isRequestSucessfull(resp):
		pass

# returns details about single transaction
# of interest to the caller
func getTransaction(hashString : String) -> Tx:
	var transactionRequest = GetTransactionRequest.new(hashString)
	transactionRequest.PlayerId = Global.PlayerInfo.PlayerId
	var resp = Global.Api.SendRequest(transactionRequest)
	if isRequestSucessfull(resp):
		var obj = GetTransactionResponse.new()
		var tx = JsonHelper.json_string_to_class(resp.Payload,obj) as GetTransactionResponse
		return tx
	return null

# returns the list of transactions for one or more 
# addresses	
func getTransactions(addressList : Array, pageSize:int = 25, skip:int = 0) -> GetTransactionsResponse:
	var transactionsRequest = GetTransactionsRequest.new(addressList)
	transactionsRequest.PlayerId = Global.PlayerInfo.PlayerId
	transactionsRequest.PageSize = pageSize
	transactionsRequest.Skip = skip
	var resp = Global.Api.SendRequest(transactionsRequest)
	print("Payload")
	print(resp.Payload)
	print("End of payload")
	if isRequestSucessfull(resp):
		var obj = GetTransactionsResponse.new()
		var tx = JsonHelper.json_string_to_class(resp.Payload,obj) as GetTransactionsResponse
		return tx
	return null
	
# returns the list of transactions for one or more 
# addresses	
func getUxtos(addressList : Array, pageSize:int = 25, skip:int = 0) -> GetUxtosRequest:
	var uxtoRequest = GetUxtosRequest.new(addressList)
	uxtoRequest.PlayerId = Global.PlayerInfo.PlayerId
	uxtoRequest.PageSize = pageSize
	uxtoRequest.Skip = skip
	var resp = Global.Api.SendRequest(uxtoRequest)
	if isRequestSucessfull(resp):
		var obj = GetUxtosResponse.new()
		var tx = JsonHelper.json_string_to_class(resp.Payload,obj) as GetUxtosResponse
		return tx
	return GetUxtosRequest.new()

# initLocalWallet must be called
# for local wallet to generate keys
# and to be able to sign transactions
func initLocalWallet(mnemonic : String) -> void:
	var request = LocalWalletRequest.new()
	request.param1 = mnemonic
	var response = self._toResult(_localWallet.go_method_call("M1", JsonHelper.class_to_json_string(request)))
	if response.errorID != 0:
		Global.GameState.ErrorOutput(response.errorDescription)

# returns the bip39 codes (words) that
# are used to generate wallet private
# and public keys
func getWaletMnemonic() -> String:
	var request = LocalWalletRequest.new()
	var response = self._toResult(_localWallet.go_method_call("M2", JsonHelper.class_to_json_string(request)))
	if response.errorID != 0:
		Global.GameState.ErrorOutput(response.errorDescription)
		return ""
	else:		
		return response.content
	
# returns the bip39 codes (words) that
# are used to generate wallet private
# and public keys
func getWaletAddress() -> String:
	var request = LocalWalletRequest.new()
	var response = self._toResult(_localWallet.go_method_call("M3", JsonHelper.class_to_json_string(request)))
	if response.errorID != 0:
		Global.GameState.ErrorOutput(response.errorDescription)
		return ""
	else:		
		return response.content	

# returns the bip39 codes (words) that
# are used to generate wallet private
# and public keys
func signTransaction(transaction:Tx) -> Tx:
	var request = LocalWalletRequest.new()
	request.param1 = JsonHelper.class_to_json_string(transaction)
	var jsonRequest = JsonHelper.class_to_json_string(request)
	print(jsonRequest)
	var signResult = _localWallet.go_method_call("M4", jsonRequest);
	print(signResult)
	var response = self._toResult(signResult)
	print(response.content, response.errorID)
	print("Got:" + response.content)
	if response.errorID != 0:
		Global.GameState.ErrorOutput(response.errorDescription)
		return null
	else:		
		var signedTx = Tx.new()
		signedTx = JsonHelper.json_string_to_class(response.content,signedTx)
		return signedTx


# will create qr code from the
# string sent to the backend
func getQrCode(code:String, size:int) -> PoolByteArray:
	var request = LocalWalletRequest.new()
	request.param1 = code
	request.param2 = String(size)
	var callResponse = _localWallet.go_method_call("M5", JsonHelper.class_to_json_string(request))
	var response = self._toResult(callResponse)
	if response.errorID != 0:
		Global.GameState.ErrorOutput(response.errorDescription)
		return PoolByteArray()
	else:		
		return Hex.hexToByteArray(response.content)
		

# sends bch amount from the player to destination address
# provide origin, destination and amount to transfer
func sendCoins(originAddress:String, destinationAddress:String, amount:int)->Tx:
	var sendRequest = SendCoinsRequest.new()
	sendRequest.OriginBchAddress = originAddress
	sendRequest.DestinationBchAddress = destinationAddress
	sendRequest.AmountToTransfer = amount	
	sendRequest.PlayerId = Global.PlayerInfo.PlayerId
	var resp = Global.Api.SendRequest(sendRequest)
	if not isRequestSucessfull(resp):
		var obj = ErrorResponse.new()
		var err = JsonHelper.json_string_to_class(resp.Payload,obj) as ErrorResponse
		Global.GameState.ErrorOutput(err.Message)
		return null

	var coinsResponse = SendCoinsResponse.new()
	coinsResponse = JsonHelper.json_string_to_class(resp.Payload,coinsResponse) as SendCoinsResponse
	
	# at this point we have transaction constructed
	# but it is not signed, signing is only done localy
	# so that key never leaves the client
	var signedTransaction = self.signTransaction(coinsResponse.Transaction)
	
	if signedTransaction != null:
		var broadcastRequest = BroadcastTransactionRequest.new()
		broadcastRequest.SignedTransaction = signedTransaction
		var broadcastRespPayload = Global.Api.SendRequest(broadcastRequest)
		if not isRequestSucessfull(broadcastRespPayload):
			var obj = ErrorResponse.new()
			var err = JsonHelper.json_string_to_class(broadcastRespPayload.Payload,obj) as ErrorResponse
			return err.Message
	return signedTransaction
	
	


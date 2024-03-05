extends Node
class_name GameClient
func get_class():
	return "GameClient"

func is_class(value):
	return value == "GameClient"
	
func _init(pInfo : PlayerInfo = null):
	if not pInfo == null:
		self._playerInfo = pInfo
		self._playerId = pInfo.PlayerId

# updates the player info
# which is needed when player 
# registers for the first time
func updatePlayerInfo(pInfo : PlayerInfo)->void:
	self._playerInfo = pInfo
	self._playerId = pInfo.PlayerId

# initialization function
func start()->void:
	# connect to pdu signal, when pdu arrives
	# process the pdu if it is for game or wallet
	var ret = Global.Api.getTcpClient().connect("onRequestReceived",self,"onRequestReceived")
	if ret != OK:
		Global.GameState.ErrorOutput("Cannot connect to onRequestReceived signal on tcp client")
	# connect to reconnect signal, if reconnection occurs pull the
	# fresh info for wallet, boxes, sphere, etc.
	ret = Global.Api.getTcpClient().connect("onReconnect",self,"onReconnect")
	if ret != OK:
		Global.GameState.ErrorOutput("Cannot connect to onReconnect signal on tcp client")
			

# signal fires when entire list has to 
# refresh as result of server reconnect
signal onBoxRefresh()
# signal fires when there is change
# in the box cache
signal onBoxDelete(box)
# when box closes
signal onBoxClose(box)
# when box goes into simulation mode
signal onBoxSimulationStart(box)
# when physics file is delivered
# for a players box
signal onPhysicsFileDelivery(box)
# when client should start playing
# for the player
signal onPlayStart(box)
# when server made payout to the player
# show him some popup
signal onPlayerWon(box)
# if player did not won the game
signal onPlayerLoose(box)
# on new box item
signal onNewBox(box)
# on box update
signal onBoxUpdate(box)
# on sphere update 
signal onSphereUpdate(sphere)
# when new player enters the box
# the list of players is sent
signal onBoxPlayerListUpdate(playerList)
# informs the system that box timer
# speedup is approved by the server
signal onBoxSpeedup(boxId, secondsToSpeedUp)

# the box cache holds list of boxes
# which are updated from the server
# as status changes, players are added
# etc	
var _boxCache : TypedList = TypedList.new(BoxInfo.new())	
var _boxCacheRetrived : bool = false
# the player box representing the box info
# selected by the player for the game
var _playersBox : BoxInfo

# set this from outside when seting up
# the game client
var _playerInfo : PlayerInfo
var _playerId : String

# the last known sphere status
var _sphereInfo : SphereInfo

# will check the response and if it is 
# error response it will show error to the
# user.	
func isRequestSucessfull(r : PduContainer) -> bool:
	if r.PduType == BhdRequestTypes.BhdErrorResponseType:
		Global.Log.debug("Got err response from server",r.PduId,r.PduType,r.Payload)
		var obj = ErrorResponse.new()
		var errResp = JsonHelper.json_string_to_class(r.Payload,obj) as ErrorResponse
		var msg = errResp.Message
		if msg.empty():msg = "No specific error!"
		Global.GameState.ErrorOutput(msg)
		return false
	return true


#
# This section is for box game
#

# will clear the cache in case of 
func clearCache()->void:
	self._boxCache.clear()
	self._sphereInfo = null

# returns the list of available boxes
# you should call this only once as 
# the boxes are updated from the 
# server
func getBoxes() -> Array:

	#var res = Global.Wallet.getTransactions(["qpjwu6kg8ud8pk9r32u63kprpd2quykzj5l4l7hwmq"],10,0)

	if self._boxCacheRetrived and self._boxCache.size() > 0:
		# dump boxes
		for b in self._boxCache.asArray():
			print(b.toString())
		return self._boxCache.asArray()
		
	var getBoxesRequest = GetBoxesRequest.new()
	getBoxesRequest.PlayerId = self._playerId;
	var resp = Global.Api.SendRequest(getBoxesRequest)
	if isRequestSucessfull(resp):
		var obj = GetBoxesResponse.new()
		var tx = JsonHelper.json_string_to_class(resp.Payload,obj) as GetBoxesResponse
		# sort the boxes
		tx.Boxes.sortAscending("MinPlayerCount")
		self._boxCache = tx.Boxes
		self._boxCacheRetrived = true
		return tx.Boxes.asArray()
	return []
	

# validates the player box
func _validateBox(box:BoxInfo)->String:
	if box == null:
		return "No such box:" + box.BoxId
	if box.Status != BoxInfo.BoxStatusOpen and box.Status != BoxInfo.BoxStatusWarmup:
		return "The box :" + box.BoxId + " is not open!"
	return ""


# asks server to join a specific box and to this request
# the server response with transaction to sign and send it
# back
func joinBox(boxId : String)->BoxJoinResponse:
	if self._playerInfo == null:
		Global.GameState.ErrorOutput("Player not set")
		return null
		
	# first find the box
	var box : BoxInfo = self._boxCache.findElement("BoxId",boxId)
	if box == null:
		Global.GameState.ErrorOutput("No such box:" + boxId)
		return null
	if box.Status != BoxInfo.BoxStatusOpen and box.Status != BoxInfo.BoxStatusWarmup:
		Global.GameState.ErrorOutput("The box :" + box.BoxId + " is not open!")
		return null
	# check if there is enough space in the box
	if box.PlayerCount >= box.MaxPlayerCount:
		Global.GameState.ErrorOutput("The box :" + box.BoxId + " is full!")
		return null
		
	# prepare the join request
	# send it and wait for respose		
	var req	= BoxJoinRequest.new()
	req.BoxId = box.BoxId
	req.BchAddress = self._playerInfo.BchAddress
	req.PlayerId = self._playerId
	req.Username = self._playerInfo.Username
	# send the request
	var resp = Global.Api.SendRequest(req)
	if isRequestSucessfull(resp):
		var obj = BoxJoinResponse.new()
		var bjr = JsonHelper.json_string_to_class(resp.Payload,obj) as BoxJoinResponse
		self._playersBox = box
		return bjr
	return null	

# exists the box, call this every time a player
# cancels the box entry
func exitBox():
	self._playersBox = null


# once the join is accepted by the server
# the client should sign the transaction
# provided in the join response. If client
# is allowed to join game should move to 
# player update settings screen
func enterBox(signedTx : Tx, noPlay : bool)->BoxEnterResponse:
	if self._playerInfo == null:
		Global.GameState.ErrorOutput("Player not set")
		return null
	
	var box : BoxInfo = self._playersBox
	if box == null:
		Global.GameState.ErrorOutput("The current players box is null")
		return null
		
	var errMsg = self._validateBox(box)
	if not errMsg.empty():
		Global.GameState.ErrorOutput(errMsg)
		return null
		
	# prepare the join request
	# send it and wait for respose		
	var req	= BoxEnterRequest.new()
	print(".......................................")
	print(box.toString())
	req.BoxId = box.BoxId
	req.PlayerId = self._playerId
	req.BchAddress = self._playerInfo.BchAddress
	req.SignedTransaction = signedTx
	req.NoGamePlay = noPlay
	# send the request
	var resp = Global.Api.SendRequest(req)
	if isRequestSucessfull(resp):
		var obj = BoxEnterResponse.new()
		var bjr = JsonHelper.json_string_to_class(resp.Payload,obj) as BoxEnterResponse
		return bjr
	return null	

# client asks the server to update player settings in a box
# like power and direction vector. If function returns a non-empty 
# string then its error message
func updateBoxSettings(boxId:String, boxSettings : PlayerBoxSettings)->String:
	if self._playerInfo == null:
		return "Player not set"
	
	var box : BoxInfo = self._playersBox
	if box == null:
		return "The current players box is null"
	
	var errMsg = self._validateBox(box)
	if not errMsg.empty():return errMsg
	# prepare the join request
	# send it and wait for respose				
	var req	= BoxPlayerSettingsUpdate.new()
	req.BoxId = boxId
	req.PlayerId = self._playerId
	req.Settings = boxSettings
	# send the request
	var resp = Global.Api.SendRequest(req)
	if resp.PduType == BhdRequestTypes.BhdErrorResponseType:
		var obj = ErrorResponse.new()
		var errResp = JsonHelper.json_string_to_class(resp.Payload,obj) as ErrorResponse
		return errResp.Message
	return ""		

# sends request to the server to speed up 
# vote request. The server returns ack or
# error response
func voteForBoxSpeedup(boxId:String)->String:
	if self._playerInfo == null:
		return "Player not set"
	var req	= BoxSpeedUpVoteRequest.new()
	req.BoxId = boxId
	req.PlayerId = self._playerId
	var resp = Global.Api.SendRequest(req)
	if resp.PduType == BhdRequestTypes.BhdErrorResponseType:
		var obj = ErrorResponse.new()
		var errResp = JsonHelper.json_string_to_class(resp.Payload,obj) as ErrorResponse
		return errResp.Message
	return ""		
	
	
# you should call clientReadyForPlayout when
# client parses the physics file and is ready
# to show the results to the player
func clientReadyForPlayout()->String:
	if self._playerInfo == null:
		return "Player not set"
	
	var box : BoxInfo = self._playersBox
	if box == null:
		return "The current players box is null"
			
	var errMsg = self._validateBox(box)
	if not errMsg.empty():return errMsg
	# prepare the join request
	# send it and wait for respose		
	var req	= ClientReadyForPlayRequest.new()
	req.BoxId = box.BoxId
	req.PlayerId = self._playerId
	var resp = Global.Api.SendRequest(req)
	if resp.PduType == BhdRequestTypes.BhdErrorResponseType:
		var obj = ErrorResponse.new()
		var errResp = JsonHelper.json_string_to_class(resp.Payload,obj) as ErrorResponse
		return errResp.Message
	return ""		
	
# when the client played the physics ball
# simulation inform the server that client
# is finished	
func clientDonePlaying()->String:
	if self._playerInfo == null:
		return "Player not set"
	
	var box : BoxInfo = self._playersBox
	if box == null:
		return "The current players box is null"
			
	var errMsg = self._validateBox(box)
	if not errMsg.empty():return errMsg
	var req = BoxPlayDoneRequest.new()
	req.BoxId = self._playersBox.BoxId
	req.PlayerId = self._playerInfo.PlayerId;
	var resp = Global.Api.SendRequest(req)
	if resp.PduType == BhdRequestTypes.BhdErrorResponseType:
		var obj = ErrorResponse.new()	
		var errResp = JsonHelper.json_string_to_class(resp.Payload,obj) as ErrorResponse
		return errResp.Message	
	return ""
	
	
# handles the reconnection event
# when client has to update box list
# and sphere info	
func onReconnect()-> void:
	Global.Log.debug("Reconnecting game client")
	self.clearCache()
	emit_signal("onBoxRefresh")
	
	
# handles requests from server
# and these are box updates like 
# status changes, box property changes
# winner announcments, etc
func onRequestReceived(req : PduContainer) -> void:
	if not isRequestSucessfull(req):return
	# when new box is created on the server
	# the client gets new box request and 
	# it should update the cache (add new box)
	if req.PduType == BhdRequestTypes.BhdNewBoxAvailableRequestType:
		var obj = BoxNewAvailableRequest.new()
		var newBox = JsonHelper.json_string_to_class(req.Payload,obj) as BoxNewAvailableRequest
		if newBox.Box != null:
			self._boxCache.addElement(newBox.Box)
			emit_signal("onNewBox", newBox.Box)
			
	# when box status changes on the server then
	# replace the box in the cache if the box is 
	# not in the cache then add it but only if satus
	# is boxopen		
	if req.PduType == BhdRequestTypes.BhdUpdateBoxRequestType:
		var obj = BoxUpdateRequest.new()
		var updatedBoxReq = JsonHelper.json_string_to_class(req.Payload,obj) as BoxUpdateRequest
		if updatedBoxReq.Box != null:
			var updatedBox = updatedBoxReq.Box
			# find the box
			var existingBox = self._boxCache.findElement("BoxId",updatedBox.BoxId)
			
			# if there is not existing box and status is open or warmupu
			# then add the box just as it arrived with new box event
			if existingBox == null and (updatedBox.Status == BoxInfo.BoxStatusOpen or updatedBox.Status == BoxInfo.BoxStatusWarmup):
				self._boxCache.addElement(updatedBox)
				emit_signal("onNewBox", updatedBox)	

			# if we have the box then update
			# the box	
			if existingBox != null:
				# if updated box status is 
				# deleting or deleted remove 
				# it from the list
				if updatedBox.Status == BoxInfo.BoxStatusDeleted or \
				   updatedBox.Status == BoxInfo.BoxStatusDeleting:
					Global.Log.error("Removing box",existingBox.Name, existingBox.BoxId)
					self._boxCache.removeElementViaField("BoxId",existingBox.BoxId)
					emit_signal("onBoxDelete", updatedBox)
				# if updated box status is closed then emit 
				# the signal. The box is closed when its full
				# or the simulation starts and we cannot
				# accept new players
				if updatedBox.Status == BoxInfo.BoxStatusClosed:
					# if this is not the players box then on close
					# should remove it from the list
					if self._playersBox != null and updatedBox.BoxId == self._playersBox.BoxId:
						self._boxCache.removeElementViaField("BoxId",existingBox.BoxId)
						self._boxCache.addElement(updatedBox)
						emit_signal("onBoxClose", updatedBox)
					else:					
						Global.Log.error("Removing box",existingBox.Name, existingBox.BoxId)
						self._boxCache.removeElementViaField("BoxId",existingBox.BoxId)
						emit_signal("onBoxDelete", updatedBox)

				# when box enters simulatio mode then player cannot
				# update box settings any more					
				if updatedBox.Status == BoxInfo.BoxStatusSimulating:				   
					if self._playersBox != null and updatedBox.BoxId == self._playersBox.BoxId:
						self._boxCache.removeElementViaField("BoxId",existingBox.BoxId)
						self._boxCache.addElement(updatedBox)
						emit_signal("onBoxSimulationStart", updatedBox)					
					else:					
						Global.Log.error("Removing box",existingBox.Name, existingBox.BoxId)
						self._boxCache.removeElementViaField("BoxId",existingBox.BoxId)
						emit_signal("onBoxDelete", updatedBox)
				
				# if in status playing
				if updatedBox.Status == BoxInfo.BoxStatusPlaying:
					if self._playersBox != null and updatedBox.BoxId == self._playersBox.BoxId:
						self._boxCache.removeElementViaField("BoxId",existingBox.BoxId)
						self._boxCache.addElement(updatedBox)
						emit_signal("onBoxUpdate", updatedBox)					
					else:					
						Global.Log.error("Removing box",existingBox.Name, existingBox.BoxId)
						self._boxCache.removeElementViaField("BoxId",existingBox.BoxId)
						emit_signal("onBoxDelete", updatedBox)
				
				# when box is open, simulating or warming up
				# update box setting to reflect the new status
				# such as player count
				if updatedBox.Status == BoxInfo.BoxStatusOpen \
				or updatedBox.Status == BoxInfo.BoxStatusWarmup:
					emit_signal("onBoxUpdate", updatedBox)	
					self._boxCache.removeElementViaField("BoxId",existingBox.BoxId)
					self._boxCache.addElement(updatedBox)
					

	
	# this request contains the playout physics data
	# and it is not json but pure binary to avoid
	# expensive json deserialization
	if req.PduType == BhdRequestTypes.BhdBoxPhysicsDeliveryRequest:
		Global.Log.debug("Got physics delivery request, size:",req.PayloadByteArray.size(),"bytes")
		if self._playersBox != null and self._playersBox.BoxId == req.Payload:
			self._playersBox.PhysicsData = req.PayloadByteArray
			emit_signal("onPhysicsFileDelivery", self._playersBox)
	
	# signals that there is new list of players available
	# for a box that the player joined at some point		
	if req.PduType == BhdRequestTypes.BhdPlayerListUpdateRequest:
		#print(req.Payload)
		var obj = BoxPlayerListUpdateRequest.new()
		var playerListRequest = JsonHelper.json_string_to_class(req.Payload,obj) as BoxPlayerListUpdateRequest		
		emit_signal("onBoxPlayerListUpdate",playerListRequest)
		
	# request from the server to the client that
	# it should start with the play out
	if req.PduType == BhdRequestTypes.BhdBoxPlayRequest:
		var obj = BoxPlayRequest.new()
		var boxPlayRequest = JsonHelper.json_string_to_class(req.Payload,obj) as BoxPlayRequest
		if self._playersBox != null and \
		   self._playerId == boxPlayRequest.PlayerId and \
		   self._playersBox.BoxId == boxPlayRequest.BoxId:
		   emit_signal("onPlayStart", self._playersBox)

	# if the client won (player) then server sends the request
	# to show who won. This request is sent once the payout is
	# done to the players bch address
	if req.PduType == BhdRequestTypes.BhdShowWinnerRequest:
		var obj = BoxShowWinnerRequest.new()
		var showWinnerRequest = JsonHelper.json_string_to_class(req.Payload,obj) as BoxShowWinnerRequest		
		if (Global.joinedBoxes.has(showWinnerRequest.BoxId) and \
		   self._playerId == showWinnerRequest.PlayerId) \
		   or \
		   (self._playersBox != null and \
		   self._playerId == showWinnerRequest.PlayerId and \
		   self._playersBox.BoxId == showWinnerRequest.BoxId):
		   emit_signal("onPlayerWon", showWinnerRequest)

	# if the client looses then this request comes from the 
	# server to show the looose popup or some sound
	if req.PduType == BhdRequestTypes.BhdShowLooserRequest:
		var obj = BoxShowLooserRequest.new()
		var showLooserRequest = JsonHelper.json_string_to_class(req.Payload,obj) as BoxShowLooserRequest		
		if (Global.joinedBoxes.has(showLooserRequest.BoxId) and \
		   self._playerId == showLooserRequest.PlayerId) \
		   or \
		   (self._playersBox != null and \
		   self._playerId == showLooserRequest.PlayerId and \
		   self._playersBox.BoxId == showLooserRequest.BoxId):
		   emit_signal("onPlayerLoose", showLooserRequest)	
	
	# when sphere gets updated, number of tries, reward goes
	# up or its closed here we get update status
	if req.PduType == BhdRequestTypes.BhdSphereUpdateRequestType:
		var obj = SphereUpdateRequest.new()
		var sphereUpdate = JsonHelper.json_string_to_class(req.Payload,obj) as SphereUpdateRequest		
		if sphereUpdate != null and sphereUpdate.Sphere != null:
			self._sphereInfo = sphereUpdate.Sphere
			emit_signal("onSphereUpdate", sphereUpdate.Sphere)	
		
	if req.PduType == BhdRequestTypes.BhdBoxSpeedUpRequest:
		var obj = BoxSpeedUpRequest.new()
		var speedUpRequest = JsonHelper.json_string_to_class(req.Payload,obj) as BoxSpeedUpRequest		
		if speedUpRequest != null:
			emit_signal("onBoxSpeedup", speedUpRequest.BoxId, speedUpRequest.SecondsToSpeedUp)	
#
# This section if for sphere game
#

# returns the sphere info, like current
# reward, number of times someone tried
# to open sphere, etc.
func getSphereInfo() -> SphereInfo:
	# if we have sphere info 
	# then return that one
	if self._sphereInfo != null:
		return self._sphereInfo
		
	var req	= SphereInfoRequest.new()
	req.PlayerId = self._playerId
	var resp = Global.Api.SendRequest(req)
	if resp.PduType == BhdRequestTypes.BhdErrorResponseType:
		var obj = ErrorResponse.new()
		var errResp = JsonHelper.json_string_to_class(resp.Payload,obj) as ErrorResponse
		Global.GameState.ErrorOutput(errResp.Message)
		return null
	var obj = SphereInfoResponse.new()
	var sphereInfo = JsonHelper.json_string_to_class(resp.Payload,obj) as SphereInfoResponse
	self._sphereInfo = sphereInfo.Sphere
	return sphereInfo.Sphere
	
# request by the player to join the 
# sphere box, on server side transaction
# is created and returned to the client
# the transaction must be signed by the
# client and sent back via enterSphere	
func joinSphere(sphereId : String, ammo : int)->SphereJoinResponse:
	var req	= SphereJoinRequest.new()
	req.PlayerId = self._playerId	
	req.PlayerBchAddress = self._playerInfo.BchAddress	
	req.SphereId = sphereId
	req.AmmoCount = ammo
	
	var resp = Global.Api.SendRequest(req)
	print(resp.Payload)	
	if resp.PduType == BhdRequestTypes.BhdErrorResponseType:
		var obj = ErrorResponse.new()
		var errResp = JsonHelper.json_string_to_class(resp.Payload,obj) as ErrorResponse
		Global.GameState.ErrorOutput(errResp.Message)
		return null
	var obj = SphereJoinResponse.new()
	var joinInfo = JsonHelper.json_string_to_class(resp.Payload,obj) as SphereJoinResponse
	return joinInfo

# calls when client wants to "try" to open a sphere
# transaction must be signed and random string is the
# integer number between X and Y
func enterSphere(sphereId : String, randomStringArr : Array, serializedTx : Tx)->SphereEnterResponse:
	var req	= SphereEnterRequest.new()
	req.PlayerId = self._playerId	
	req.PlayerBchAddress = self._playerInfo.BchAddress	
	req.SphereId = sphereId
	req.RandomString = randomStringArr
	req.SignedTransaction = serializedTx
	var resp = Global.Api.SendRequest(req)
	if resp.PduType == BhdRequestTypes.BhdErrorResponseType:
		var obj = ErrorResponse.new()
		var errResp = JsonHelper.json_string_to_class(resp.Payload,obj) as ErrorResponse
		Global.GameState.ErrorOutput(errResp.Message)
		return null
	var obj = SphereEnterResponse.new()
	var enterInfo = JsonHelper.json_string_to_class(resp.Payload,obj) as SphereEnterResponse
	return enterInfo
	
	

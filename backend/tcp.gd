extends Node
class_name TcpClient

# constants
const Timeout = 20 * 1000

# public and private properties
var _host = ""
var _port = 0
var _status: int = 0
var _tcpStream: StreamPeerTCP 
var _sslStream : StreamPeerSSL
# mutex for protecting socket write
var _socketLock : Mutex = Mutex.new()
var _isShutdownInProgress : bool = false
# thread that constantly reads the 
# socket and tries to parse pdu
var _readThread : Thread = Thread.new()
# magic number which is used to detect incoming pdu
# nothing special about it, just a combination of numbers
# that should not appear anywhere else in the pdu
var _pduMagicNumber : PoolByteArray = PoolByteArray([255,254,253,252,251,250])

# the dictionary that holds request and response
# used by the syncSendRequest method. That method sets
# the dictionery entry with key requestId and value null
# the reading thread sets the actual pdu when it is received
var _responseDictionary : Dictionary = Dictionary()

# must start from 1
# as 0 is reserved for 
# the server request
var _pduId : int = 1

# initializes the tcp client (constructor)
func _init(host:String, port:int):
	self._host = host
	self._port = port
	self._tcpStream =  StreamPeerTCP.new()
	self._sslStream = StreamPeerSSL.new()

# the onRequestReceived signals that will emit once the tcp 
# client gets the request from server, an
# pdu that is not the result of the 
# client request
signal onRequestReceived(pduContainer)
signal onReconnect()
signal onConnect()
signal onDisconnect()

# will open tcp connection
# toward server
func connectToServer(isReconnect : bool = false)->int:
	self._isShutdownInProgress = false
	var connectionRes = self._tcpStream.connect_to_host(self._host,self._port)
	if connectionRes == OK:
		self._status = self._tcpStream.get_status()
		if self._status == self._tcpStream.STATUS_ERROR:
			return ERR_CANT_CONNECT
		# wait until status 
		# is connected or timeout
		# occurs
		var timeout = 0;
		while true:
			self._status = self._tcpStream.get_status()
			if self._status == self._tcpStream.STATUS_CONNECTED:
				# for large data transfer this 
				# should be set to false	
				self._tcpStream.set_no_delay(true)				
				break
			timeout = timeout + 100
			OS.delay_msec(100)
			if timeout > self.Timeout:
				return ERR_TIMEOUT

		timeout = 0;					
		self._sslStream.connect_to_stream(self._tcpStream,false,"api.bunnyhedger.com")			
		# wait for handshake to complete
		while true:
			var sslStatus = self._sslStream.get_status()
			if sslStatus == self._sslStream.STATUS_ERROR_HOSTNAME_MISMATCH:
				print("STATUS_ERROR_HOSTNAME_MISMATCH")
			if sslStatus == self._sslStream.STATUS_CONNECTED:
				# start the read thread
				if not self._readThread.is_active():
					self._readThread.start(self, "_read")
				emit_signal("onConnect")
				break
			timeout = timeout + 100			
			OS.delay_msec(100)
			if timeout > self.Timeout:
				return ERR_TIMEOUT
		
	# if this was reconnect then reconnection signal
	# shall be raised in order to invalidate box list 
	# info and balances
	if isReconnect == true and connectionRes == OK:
		emit_signal("onReconnect")
		
	# finished, ssl connection up			
	return connectionRes


# will kill the connection
func disconnectFromServer()->void:
	self._isShutdownInProgress = true
	self._sslStream.disconnect_from_stream()
	self._tcpStream.disconnect_from_host()
	self._status = self._tcpStream.STATUS_NONE
	emit_signal("onDisconnect")

# true if connection is still active
func isConnected()->bool:
	return self._status == self._tcpStream.STATUS_CONNECTED

# first 4 bytes is magic number 0xFFF...
# this is used to track the start of pdu in 
# the socket stream
# next 4 bytes are pdu id or the request id
# used to correlate request and response
# next 4 bytes is the size of the content
# 13th and 14th byte is the request type
func makeHeader(requestType:int, contentLength:int)->PoolByteArray:
	var arr = StreamPeerBuffer.new()
	arr.put_data(self._pduMagicNumber)
	arr.put_u32(self._pduId)
	arr.put_u32(contentLength)
	arr.put_u16(requestType)
	return arr.data_array


# will create object representation as json and
# extract the request type which ever data object
# has for this protocl
func makePayload(obj:Object) -> Array:
	var methodsArray = obj.get_method_list()
	var rqType = obj.call("getRequestType")
	var jsonContent = JsonHelper.class_to_json_string(obj)
	if rqType == null or jsonContent == null:
		return [null, null]
	return [rqType,jsonContent]

# validates the connection, if down
# this will try to reconnect
func _validateConnection()->bool:
	if self._isShutdownInProgress:
		return false
	# if status is not connected
	# do the reconnection
	self._status = self._tcpStream.get_status()
	if self._status == self._tcpStream.STATUS_NONE or self._status == self._tcpStream.STATUS_ERROR:
		emit_signal("onDisconnect")
		self.disconnectFromServer()
		# reconnect
		self.connectToServer(true)
		return false
	# seems connection is healthy
	return true

# function will block
# until there is something to read from the 
# socket. If the read value is the magic
# number then it will start to parse 
# the pdu
func _read():
	while not self._isShutdownInProgress:
		self._validateConnection()
		# is there something in the socket?
		if self._isShutdownInProgress : return		
		self._sslStream.poll()
		var availableBytes = self._sslStream.get_available_bytes()
		while availableBytes > 0 and not self._isShutdownInProgress:
			if availableBytes >= 6:
				# first get the total length of the pdu
				# and the type of the pdu
				var mpa = self._sslStream.get_partial_data(6)[1]
				if mpa[0] == _pduMagicNumber[0] and \
				   mpa[1] == _pduMagicNumber[1] and \
				   mpa[2] == _pduMagicNumber[2] and \
				   mpa[3] == _pduMagicNumber[3] and \
				   mpa[4] == _pduMagicNumber[4] and \
				   mpa[5] == _pduMagicNumber[5]:
					# it seems this is the start of the pdu
					# and it must be parsed
					var pc = self._parsePdu()
					Global.Log.debug("Server-> ",pc.PduId, pc.PduType,"and content:",pc.Payload)
					if pc.PduId == 0:
						emit_signal("onRequestReceived", pc)
					else:
						Global.Log.debug("Server-> ",pc.PduId, pc.PduType,"and content:",pc.Payload)
						# if there is entry in the response
						# dictionary populate the same
						# cause sync request might be waiting
						if self._responseDictionary.has(pc.PduId):
							_responseDictionary[self._pduId] = pc
			# if disconnect is called
			# exit the read thread
			if self._isShutdownInProgress : return
			OS.delay_msec(10)				
			self._validateConnection()
			if self._isShutdownInProgress : return
			self._sslStream.poll()
			availableBytes = self._sslStream.get_available_bytes()				
		# if disconnect is called
		# exit the read thread
		if self._isShutdownInProgress : return
		# if there is less than 4 bytes
		# then just sleep
		OS.delay_msec(10)

# once the header is confirmed to start
# with the magic number this procedure
# will try to parse incoming pdu or timeout
# trying
func _parsePdu() -> PduContainer:
	var headerAvailableBytes = 0
	var timeout = 0;
	var availableBytes = 0
	var pduContainer = PduContainer.new()
	while true:
		if not self._validateConnection() : 
			pduContainer.IsSucessfull = false
			pduContainer.IsTimeout = true
			return pduContainer
		self._sslStream.poll()
		headerAvailableBytes = self._sslStream.get_available_bytes()
		if headerAvailableBytes >= 10:
			break
		timeout += + 100
		OS.delay_msec(10)
		if timeout > self.Timeout:
			pduContainer.ErrorInfo = "Timeout while waiting for pdu header"
			return pduContainer
			
	# extract pduId, content length and pdu type			
	pduContainer.PduId = self._sslStream.get_u32()
	pduContainer.PayloadLength = self._sslStream.get_u32()
	pduContainer.PduType = self._sslStream.get_u16()

	# wit for the whole pdu content is available
	timeout = 0
	var contentPayload = PoolByteArray([])
	var remainingPayloadLength = pduContainer.PayloadLength
	var bytesToRead = 0
	while true:
		self._sslStream.poll()
		availableBytes = self._sslStream.get_available_bytes()
		if availableBytes > 0:
			# calculate how much to read
			# from the stream
			if availableBytes > remainingPayloadLength:
				bytesToRead = remainingPayloadLength
			else:
				bytesToRead = availableBytes
			# get the partial data and put into contentPayload array
			var partialData =  self._sslStream.get_partial_data(bytesToRead)[1]
			# append read bytes to content payload poolbyte array
			contentPayload.append_array(PoolByteArray(partialData))
			# substract from remainingPayloadLength number of bytes read
			remainingPayloadLength = remainingPayloadLength - bytesToRead
			if contentPayload.size() >= pduContainer.PayloadLength:
				break
		# update timeout until its finished
		timeout = timeout + 10
		OS.delay_msec(10)
		if timeout > self.Timeout:
			pduContainer.ErrorInfo = "Timeout while waiting for pdu header"
			pduContainer.IsTimeout = true
	
	# if this is physics delivery
	# then there is no conversion to json
	# and its hard coded here cause there
	# is no effective way to slice array later
	if pduContainer.PduType == BhdRequestTypes.BhdBoxPhysicsDeliveryRequest:
		pduContainer.Payload = contentPayload.subarray(0,35).get_string_from_utf8()
		pduContainer.PayloadByteArray = contentPayload.subarray(36,contentPayload.size()-1)

	# all other requests
	# are parsed as json
	else:
		#var payloadArr = self._sslStream.get_partial_data(pduContainer.PayloadLength)[1]
		pduContainer.Payload = contentPayload.get_string_from_utf8()

	if not pduContainer.IsTimeout :
		pduContainer.IsSucessfull = true
	
	# if it has timeout then read the remaining 
	# bytes thus clearing the socket
	if pduContainer.IsTimeout and availableBytes > 0:
		self._sslStream.get_partial_data(availableBytes)
	return pduContainer	


# will send the request to server and wait 
# for the response. Once response is received
# it will be converted from json to real object
# and returned. Timeout is set via
# Timeout property (in seconds)
func _sendRequest(obj: Object) -> int:
	if obj == null:
		return -1
		
	# increase the pdu id
	self._pduId += 1
	# pack the content		
	var payload = self.makePayload(obj)
	# process json request, put it into byte array
	var jsonString:String = (payload[1] as String)
	Global.Log.debug("Client-> ",self._pduId, payload[0],"and content:",jsonString)
	var jsonToByteArrayStream = StreamPeerBuffer.new()
	jsonToByteArrayStream.put_data(jsonString.to_utf8())
	var payloadLen = jsonToByteArrayStream.data_array.size()
	var dataPdu = self.makeHeader((payload[0] as int),payloadLen)
	dataPdu += jsonToByteArrayStream.data_array

	# write request to socket	
	# and return pduId ot the caller
	#self._socketLock.lock()
	# write to the socket
	self._socketLock.lock()
	var putDataRes = self._sslStream.put_data(dataPdu)
	self._socketLock.unlock()
	if putDataRes != OK:
		return -1
	#self._socketLock.unlock()
	return self._pduId
	
	

 
# syncRequest will send the request and wait 
# for the response for specified timeout
func sendSyncRequest(obj : Object, timeout : int = Timeout) -> PduContainer :
	self._validateConnection()
	var requestId = self._sendRequest(obj)
	var pc = PduContainer.new()
	pc.PduId = requestId
	self._responseDictionary[requestId] = null
	if requestId == -1:
		pc.PduId = requestId
		pc.IsSucessfull = false
		pc.IsTimeout = false
		pc = PduContainer.new()
		pc.ErrorInfo = "Failed to send request"
		self._responseDictionary.erase(requestId)
		return pc
		
	var waitTime = 0;	
	while true:
		# check if there is entry in the dictionary
		# if there is and its not null return
		# the PduContainer
		var dictPc = self._responseDictionary[requestId];
		if dictPc != null:
			self._responseDictionary.erase(requestId)
			return dictPc
		
		# if no entry then
		# wait until timeout
		waitTime = waitTime + 10
		OS.delay_msec(10)
		if waitTime > timeout:
			pc.PduId = requestId
			pc.IsSucessfull = false
			pc.IsTimeout = true
			pc.ErrorInfo = "Timeout while waiting for pdu header"
			self._responseDictionary.erase(requestId)
			return pc
	return pc		


extends Node
class_name PduContainer

var PduId : int = 0
var IsSucessfull : bool = false
var IsTimeout : bool = false
var PduType : int = 0
var ErrorInfo : String = "OK"
var PayloadLength : int = 0
var Payload : String
var PayloadByteArray : PoolByteArray
var _parsedObject : Object = null

# validates the pdu, returns
# true if payload can be converted
# to model object
func _validate() -> bool :
	if not self.IsSucessfull:
		 return false
	if Payload.length() == 0:
		 return false
	return true

func toString() -> String:
	var res = "PduId:" + String(PduId) + "\n"
	res += "IsSucessfull:" + String(IsSucessfull) + "\n"
	res += "IsTimeout:" + String(IsTimeout) + "\n"
	res += "PduType:" + String(PduType) + "\n"
	res += "ErrorInfo:" + ErrorInfo + "\n"
	res += "PayloadLength:" + String(PayloadLength) + "\n"
	res += "Payload:" + String(Payload) + "\n"
	return res
	


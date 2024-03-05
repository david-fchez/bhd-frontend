extends Node
class_name ErrorResponse
func get_class():
	return "ErrorResponse"

func is_class(value):
	return value == "ErrorResponse"


var Message : String = ""
func _init(msg : String = ""):
	self.Message = msg

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdErrorResponseType


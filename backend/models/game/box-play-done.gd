extends Node
class_name BoxPlayDoneRequest

func get_class():
	return "BoxPlayDoneRequest"

func is_class(value):
	return value == "BoxPlayDoneRequest"

var PlayerId    : String
var BoxId 	    : String

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdClientPlayDoneRequest
	

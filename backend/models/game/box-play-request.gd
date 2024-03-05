extends Node
class_name BoxPlayRequest

func get_class():
	return "BoxPlayRequest"

func is_class(value):
	return value == "BoxPlayRequest"

var PlayerId    : String
var BoxId 	    : String

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdBoxPlayRequest
	

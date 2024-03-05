extends Node
class_name ClientReadyForPlayRequest

func get_class():
	return "ClientReadyForPlayRequest"

func is_class(value):
	return value == "ClientReadyForPlayRequest"

var PlayerId : String
var BchAddress : String
var BoxId 	   : String

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdClientReadyForPlayRequest
	

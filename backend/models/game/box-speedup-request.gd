extends Node
class_name BoxSpeedUpRequest

func get_class():
	return "BhdBoxSpeedUpRequest"

func is_class(value):
	return value == "BhdBoxSpeedUpRequest"

var BoxId 	          : String
var SecondsToSpeedUp : int

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdBoxSpeedUpVoteRequest
	


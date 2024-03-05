extends Node
class_name BoxSpeedUpVoteRequest

func get_class():
	return "BoxSpeedUpVoteRequest"

func is_class(value):
	return value == "BoxSpeedUpVoteRequest"

var BoxId 	          : String
var PlayerId		  : String

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdBoxSpeedUpVoteRequest
	


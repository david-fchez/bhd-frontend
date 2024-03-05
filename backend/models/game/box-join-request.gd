extends Node
class_name BoxJoinRequest

func get_class():
	return "BoxJoinRequest"

func is_class(value):
	return value == "BoxJoinRequest"

var PlayerId : String
var Username : String
var BchAddress : String
var BoxId 	   : String

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdJoinBoxRequest
	

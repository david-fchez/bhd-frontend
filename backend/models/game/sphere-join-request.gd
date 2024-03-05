extends Node
class_name SphereJoinRequest
func get_class():
	return "SphereJoinRequest"

func is_class(value):
	return value == "SphereJoinRequest"
	
var PlayerId         : String
var SphereId         : String
var PlayerBchAddress : String
var AmmoCount 		 : int

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdJoinSphereJoinRequestType

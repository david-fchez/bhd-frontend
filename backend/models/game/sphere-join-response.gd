extends Node
class_name SphereJoinResponse
func get_class():
	return "SphereJoinResponse"

func is_class(value):
	return value == "SphereJoinResponse"
	
var PlayerId         : String
var SphereId         : String
var PlayerBchAddress : String
var Transaction      : Tx = Tx.new()

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdJoinSphereJoinResponseType

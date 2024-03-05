extends Node
class_name GetUxtosResponse
func get_class():
	return "GetUxtosResponse"

func is_class(value):
	return value == "GetUxtosResponse"
		
var BalanceSat : int = 0
var BalanceBch : float = 0
var Inputs     : TypedList = TypedList.new(UxtoTransaction.new())
var InputCount : int 
func _init():
	pass

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdGetUxtosResponseType

extends Node
class_name GetBalanceResponse
func get_class():
	return "GetBalanceResponse"

func is_class(value):
	return value == "GetBalanceResponse"
		
var BalanceSat : int = 0
var BalanceBch : float = 0

func _init():
	pass

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdGetBalanceResponseType

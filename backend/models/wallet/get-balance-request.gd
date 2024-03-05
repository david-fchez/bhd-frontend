extends Node
class_name GetBalanceRequest
func get_class():
	return "GetBalanceRequest"

func is_class(value):
	return value == "GetBalanceRequest"
		
var PlayerId : String
var address : Array

func _init(arr : Array = []):
	for addr in arr:
		self.address.append(addr)
	pass

func addAddress(addr : String) -> void:
	self.address.append(addr)

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdGetBalanceRequestType

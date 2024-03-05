extends Node
class_name GetTransactionsRequest
func get_class():
	return "GetTransactionsRequest"

func is_class(value):
	return value == "GetTransactionsRequest"
		
var PlayerId : String		
var address : Array
var Skip : int = 0
var PageSize : int = 0

func _init(arr : Array = []):
	for addr in arr:
		self.address.append(addr)
	pass
	
func addAddress(addr : String) -> void:
	self.address.append(addr)

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdGetTransactionsRequestType

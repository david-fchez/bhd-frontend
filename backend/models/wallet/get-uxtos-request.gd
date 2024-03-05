extends Node
class_name GetUxtosRequest
func get_class():
	return "GetUxtosRequest"

func is_class(value):
	return value == "GetUxtosRequest"

var PlayerId : String		
var address : Array
var Skip : int = 0
var PageSize : int = 0

func _init(arr : Array = []):
	for addr in arr:
		self.address.append(addr)
	pass

func addAddress(addr : String) -> void:
	self.Address.append(addr)

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdGetUxtosRequestType

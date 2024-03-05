extends Node
class_name BoxPlayerListUpdateRequest

func get_class():
	return "BoxPlayerListUpdateRequest"

func is_class(value):
	return value == "BoxPlayerListUpdateRequest"

var BoxId : String
var Players : TypedList = TypedList.new(BoxPlayerEntry.new())
var PduId: String

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdPlayerListUpdateRequest
	

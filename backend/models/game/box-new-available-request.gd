extends Node
class_name BoxNewAvailableRequest

func get_class():
	return "BoxNewAvailableRequest"

func is_class(value):
	return value == "BoxNewAvailableRequest"

var Box : BoxInfo = BoxInfo.new()

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdNewBoxAvailableRequestType
	

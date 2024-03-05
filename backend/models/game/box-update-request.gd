extends Node
class_name BoxUpdateRequest

func get_class():
	return "BoxUpdateRequest"

func is_class(value):
	return value == "BoxUpdateRequest"

var Box : BoxInfo = BoxInfo.new()

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdUpdateBoxRequestType
	

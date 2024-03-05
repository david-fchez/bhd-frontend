extends Node
class_name GetBoxesRequest

func get_class():
	return "GetBoxesRequest"

func is_class(value):
	return value == "GetBoxesRequest"

var PlayerId : String

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdGetBoxesRequest

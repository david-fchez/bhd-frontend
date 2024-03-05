extends Node
class_name GetBoxesResponse

func get_class():
	return "GetBoxesResponse"

func is_class(value):
	return value == "GetBoxesResponse"

var Boxes : TypedList = TypedList.new(BoxInfo.new())

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdGetBoxesResponse
	

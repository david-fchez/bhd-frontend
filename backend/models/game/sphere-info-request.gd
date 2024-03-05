extends Node
class_name SphereInfoRequest
func get_class():
	return "SphereInfoRequest"

func is_class(value):
	return value == "SphereInfoRequest"
	
var PlayerId : String
	
# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdGetSphereInfoRequestType

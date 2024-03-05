extends Node
class_name SphereUpdateRequest
func get_class():
	return "SphereUpdateRequest"

func is_class(value):
	return value == "SphereUpdateRequest"
	
var Sphere : SphereInfo = SphereInfo.new()

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdSphereUpdateRequestType

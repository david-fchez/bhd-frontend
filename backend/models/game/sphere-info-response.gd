extends Node
class_name SphereInfoResponse
func get_class():
	return "SphereInfoResponse"

func is_class(value):
	return value == "SphereInfoResponse"
	
var Sphere : SphereInfo = SphereInfo.new()

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdGetSphereInfoResponseType



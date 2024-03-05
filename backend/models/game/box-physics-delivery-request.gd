extends Node
class_name BoxPhysicsDeliveryRequest

func get_class():
	return "BoxPhysicsDeliveryRequest"

func is_class(value):
	return value == "BoxPhysicsDeliveryRequest"

var BoxId 	    : String
var PhysicsData : PoolByteArray

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdBoxPhysicsDeliveryRequest
	

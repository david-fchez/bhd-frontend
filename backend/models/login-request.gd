class_name LoginRequest
func get_class():
	return "LoginRequest"

func is_class(value):
	return value == "LoginRequest"
		
var Username = ""
var Password = ""

func _init():
	pass

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdLoginRequestType



class_name LoginResponse
func get_class():
	return "LoginResponse"

func is_class(value):
	return value == "LoginResponse"
		
var Authenticated = false
var Info = ""
var Host = ""
var Port = 0
	

func _init():
	pass

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdLoginResponseType
 

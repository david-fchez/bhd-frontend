class_name RegisterRequest
func get_class():
	return "RegisterRequest"

func is_class(value):
	return value == "RegisterRequest"

var BchAddress : String
		
func _init():
	pass

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdRegisterBchAddressType



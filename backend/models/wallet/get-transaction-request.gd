class_name GetTransactionRequest
func get_class():
	return "GetTransactionRequest"

func is_class(value):
	return value == "GetTransactionRequest"
		
var PlayerId : String		
var Hash : String

func _init(hashString : String = ""):
	self.Hash = hashString

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdGetTransactionRequestType

extends Node
class_name SendCoinsRequest
func get_class():
	return "SendCoinsRequest"

func is_class(value):
	return value == "SendCoinsRequest"
		
var OriginBchAddress : String
var DestinationBchAddress : String
var AmountToTransfer : int		
var PlayerId: String

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdSendCoinsRequestType

extends Node
class_name SendCoinsResponse
func get_class():
	return "SendCoinsResponse"

func is_class(value):
	return value == "SendCoinsResponse"
	
var OriginBchAddress : String
var DestinationBchAddress : String
var AmountToTransfer : int		
var Transaction : Tx = Tx.new()

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdSendCoinsResponseType

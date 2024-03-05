extends Node
class_name BroadcastTransactionRequest

func get_class():
	return "BroadcastTransactionRequest"

func is_class(value):
	return value == "BroadcastTransactionRequest"
	
var SignedTransaction : Tx = Tx.new()

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdBroadcastTransactionRequestType

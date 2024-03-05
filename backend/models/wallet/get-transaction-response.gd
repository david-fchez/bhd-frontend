extends Node
class_name GetTransactionResponse
func get_class():
	return "GetTransactionResponse"

func is_class(value):
	return value == "GetTransactionResponse"

	
var transaction : Tx

func _init():
	self.transaction = Tx.new()

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdGetTransactionResponseType

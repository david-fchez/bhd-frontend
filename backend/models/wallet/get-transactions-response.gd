extends Node
class_name GetTransactionsResponse
func get_class():
	return "GetTransactionsResponse"

func is_class(value):
	return value == "GetTransactionsResponse"
		
var transactions     : TypedList = TypedList.new(Tx.new())
var transactionCount : int
func _init():
	pass
	

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdGetTransactionsResponseType

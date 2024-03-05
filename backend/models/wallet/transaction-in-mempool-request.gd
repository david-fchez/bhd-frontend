class_name TransactionInMemPoolRequest
func get_class():
	return "TransactionInMemPoolRequest"

func is_class(value):
	return value == "TransactionInMemPoolRequest"
		
var Transaction : Tx = Tx.new()

func _init():
	pass
	
# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdMemPoolTransactionRequestType

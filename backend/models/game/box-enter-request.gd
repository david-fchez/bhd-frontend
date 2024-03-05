extends Node
class_name BoxEnterRequest

func get_class():
	return "BoxEnterRequest"

func is_class(value):
	return value == "BoxEnterRequest"

var PlayerId          : String
var BoxId 	          : String
var SignedTransaction : Tx = Tx.new()
var NoGamePlay        : bool
var BchAddress		  : String

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdEnterBoxRequest
	

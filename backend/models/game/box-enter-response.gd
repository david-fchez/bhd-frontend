extends Node
class_name BoxEnterResponse

func get_class():
	return "BoxEnterResponse"

func is_class(value):
	return value == "BoxEnterResponse"

var PlayerId          : String
var BoxId 	          : String
var SignedTransaction : Tx = Tx.new()
var EntryAllowed      : String
var Info              : String

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdEnterBoxResponse
	

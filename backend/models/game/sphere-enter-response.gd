extends Node
class_name SphereEnterResponse
func get_class():
	return "SphereEnterResponse"

func is_class(value):
	return value == "SphereEnterResponse"
	
var PlayerId              : String
var SphereId              : String
var PlayerBchAddress      : String	
var IsWinner              : bool
var PayoutTransactionHash : String

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdEnterSphereEnterResponseType

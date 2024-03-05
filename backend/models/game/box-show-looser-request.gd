extends Node
class_name BoxShowLooserRequest

func get_class():
	return "BoxShowLooserRequest"

func is_class(value):
	return value == "BoxShowLooserRequest"

var PlayerId    : String
var BoxId 	    : String
var BoxName     : String
var PayoutTransactionHash : String
var TotalRewardSat : int
var TotalRewardBch : float


# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdShowLooserRequest
	

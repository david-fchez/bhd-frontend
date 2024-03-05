extends Node
class_name BoxShowWinnerRequest

func get_class():
	return "BoxShowWinnerRequest"

func is_class(value):
	return value == "BoxShowWinnerRequest"

var PlayerId    : String
var BoxId 	    : String
var BoxName     : String
var PayoutTransactionHash : String
var PayoutBchAddress : String
var TotalRewardSat : int
var TotalRewardBch : float


# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdShowWinnerRequest
	

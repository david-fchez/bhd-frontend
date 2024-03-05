extends Reference
class_name BoxJoinResponse

func get_class():
	return "BoxJoinResponse"

func is_class(value):
	return value == "BoxJoinResponse"

var PlayerId    : String
var BoxId 	    : String
var Transaction : Tx = Tx.new()
var JoinAllowed : bool
var EntryFeeSat : int
var EntryFeeBch : float
var Info        : String

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdJoinBoxResponse
	

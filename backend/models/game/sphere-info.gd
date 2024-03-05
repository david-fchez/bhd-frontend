extends Node
class_name SphereInfo
func get_class():
	return "SphereInfo"

func is_class(value):
	return value == "SphereInfo"

const StatusOpen       = 1
const StatusClosed     = 2


var SphereId : String
var EntryFee : int
var Reward   : int	
var Status   : int

# Get readable stauts
static func parse_status(status: int):
	if status == StatusOpen: 
		return "Open"
	if status == StatusClosed:
		return "Closed"
	

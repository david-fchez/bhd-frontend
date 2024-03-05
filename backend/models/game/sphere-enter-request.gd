extends Node
class_name SphereEnterRequest
func get_class():
	return "SphereEnterRequest"

func is_class(value):
	return value == "SphereEnterRequest"
	
var PlayerId          : String
var SphereId          : String
var PlayerBchAddress  : String	
var SignedTransaction : Tx = Tx.new()
# if player pays from 1 then here we have
# one random number between 0 and 21,000,000
# if he pays for 100 tries then put 100 items
# in this array
var RandomString      : Array

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdEnterSphereEnterRequestType

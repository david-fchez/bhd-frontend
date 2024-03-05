extends Node
class_name UxtoTransaction
func get_class():
	return "UxtoTransaction"

func is_class(value):
	return value == "UxtoTransaction"
		
var Hash : String
var Index : int
var PkScript : String
var Value : int

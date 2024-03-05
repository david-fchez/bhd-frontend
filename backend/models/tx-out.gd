extends Node
class_name TxOut
func get_class():
	return "TxOut"

func is_class(value):
	return value == "TxOut"
		
var Value   : int
var Spent   : bool
var PkScript: String
var Address : String

extends Node
class_name TxIn
func get_class():
	return "TxIn"

func is_class(value):
	return value == "TxIn"
		
var Sequence  : int
var Value     : int
var PrevHash  : String
var PubScript : String
var PrevIndex : int
var Signature : String

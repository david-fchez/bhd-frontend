extends Node
class_name Tx
func get_class():
	return "Tx"

func is_class(value):
	return value == "Tx"
	
func _init():
	var x = Inputs.getNewElement()
	
var Hash       : String
var DateTime   : int
var Size       : int
var Height     : int
var Index      : int
var Version    : int
var LockTime   : int
var Inputs     : TypedList = TypedList.new(TxIn.new())
var Outputs    : TypedList = TypedList.new(TxOut.new())
var InputVal   : int
var OutputVal  : int
var CashBack   : int
var NetworkFee : int

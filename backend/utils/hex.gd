extends Node
class_name Hex

# will convert hex string to PoolByteArray
# and is used here to convert image date
# from the backend
static func hexToByteArray(hex:String) -> PoolByteArray:
	var hex_length := hex.length()
	if hex_length % 2 == 1:
		push_error("Not even length hex input")
		return PoolByteArray()

	# warning-ignore:integer_division
	var byte_length := hex_length / 2
	var result := PoolByteArray()
	result.resize(byte_length)
	for byte_index in byte_length:
		var hex_index := int(byte_index) * 2
		var hex_couple := hex.substr(hex_index, 2)
		result[byte_index] = ("0x" + hex_couple).hex_to_int()
	return result

# converts the byte array to hex string
static func byteArrayToHex(arr : PoolByteArray) -> String:
	return arr.hex_encode()

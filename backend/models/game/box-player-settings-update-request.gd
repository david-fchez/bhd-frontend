extends Node
class_name BoxPlayerSettingsUpdate

func get_class():
	return "BoxPlayerSettingsUpdate"

func is_class(value):
	return value == "BoxPlayerSettingsUpdate"

var PlayerId    : String
var BoxId 	    : String
var Settings    : PlayerBoxSettings = PlayerBoxSettings.new()

# returns the specific request type
func getRequestType()-> int:
	return BhdRequestTypes.BhdPlayerBoxSettingsUpdateRequest
	

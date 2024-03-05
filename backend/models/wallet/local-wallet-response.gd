class_name LocalWalletResponse

#backend errorCode, 0=ok this should be an enum
var errorID: int
#the stack trace or description of the error
var errorDescription: String
#the json response from the backend if no error, parse it to an object
var content: String

func _init(data: Dictionary):
	if "errorID" in data:
		errorID = data.errorID
	if "content" in data:
		content = data.content
	if "errorDescription" in data: 
		errorDescription = data.errorDescription

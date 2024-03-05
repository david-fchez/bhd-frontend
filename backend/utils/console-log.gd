extends Node
class_name ConsoleLog
func get_class():
	return "ConsoleLog"

func is_class(value):
	return value == "ConsoleLog"

const LogLevelDebug = 1
const LogLevelInfo =  2
const LogLevelError = 3
const LogLevelSilent = 999


var _currentLogLevel : int = LogLevelError

# sets the current logging level
func setLogLevel(level:int) -> void:
	if level > 3 or level < 1:
		self._currentLogLevel = LogLevelDebug
	else:
		self._currentLogLevel = level	


# put debug info on console
func debug(m1,m2=null,m3=null,m4=null,m5=null,m6=null,m7=null,m8=null,m9=null,m10=null)->void:
	if _currentLogLevel <= LogLevelDebug:
		self._log("DBG",m1,m2,m3,m4,m5,m6,m7,m8,m9,m10)

# put debug info on console
func info(m1,m2:=null,m3=null,m4=null,m5=null,m6=null,m7=null,m8=null,m9=null,m10=null)->void:
	if _currentLogLevel <= LogLevelInfo:
		self._log("INF",m1,m2,m3,m4,m5,m6,m7,m8,m9,m10)

# put debug info on console
func error(m1,m2:=null,m3=null,m4=null,m5=null,m6=null,m7=null,m8=null,m9=null,m10=null)->void:
	if _currentLogLevel <= LogLevelError:
		self._log("ERR",m1,m2,m3,m4,m5,m6,m7,m8,m9,m10)
	
func _log(pref:String, m1,m2=null,m3=null,m4=null,m5=null,m6=null,m7=null,m8=null,m9=null,m10=null) -> void:
	if _currentLogLevel == LogLevelSilent: return
	var line : String = ""
	line = line + pref + " "
	var d = OS.get_datetime()
	var now = String(d["year"]) + "-" + String(d["month"]) + "-" + String(d["day"]) + " " + Time.get_time_string_from_system()
	line = line + now + "->"
	line = line + String(m1)
	if m2 != null:
		line = line + " " + String(m2)
	if m3 != null:
		line = line + " " + String(m3)
	if m4 != null:
		line = line + " " + String(m4)
	if m5 != null:
		line = line + " " + String(m5)
	if m6 != null:
		line = line + " " + String(m6)
	if m7 != null:
		line = line + " " + String(m7)
	if m8 != null:
		line = line + " " + String(m8)
	if m9 != null:
		line = line + " " + String(m9)
	if m10 != null:
		line = line + " " + String(m10)
	print(line)	




extends Reference
class_name SettingsManager

var _settingsFile : ConfigFile
const configFileUri : String = "user://settings.cfg"

#load settings file in constructor
func _init():
	self._settingsFile = ConfigFile.new()
	var res = self._settingsFile.load(self.configFileUri)
	#save file if it doesn't exist
	if res != OK:
		self._settingsFile.save(self.configFileUri)

#call this to persist changes
func saveSettings()->void:
	self._settingsFile.save(self.configFileUri)

#just in case, we shouldn't need to do this
func reloadSetting()->void:
	var res = self._settingsFile.load(self.configFileUri)
	#save file if it doesn't exist
	if res != OK:
		self._settingsFile.save(self.configFileUri)

######
## add getters/setters after this
######
func getMasterVolume()->float:
	return self._settingsFile.get_value("Settings", "Volume", 50)

# setting the volume is done in
# 0 (-60dB) to 100 (0dB) range
func setMasterVolume(newVol: float)->void:
	self._settingsFile.set_value("Settings", "Volume", newVol)
	self.saveSettings()


func getVolumeMuted()->bool:
	return self._settingsFile.get_value("Settings", "Muted", false)

func setVolumeMuted(isMuted: bool)->void:
	self._settingsFile.set_value("Settings", "Muted", isMuted)
	self.saveSettings()


func getAutoEnterBox()->bool:
	return self._settingsFile.get_value("Settings", "AutoEnter", false)

func setAutoEnterBox(autoEnter: bool)->void:
	self._settingsFile.set_value("Settings", "AutoEnter", autoEnter)
	self.saveSettings()


func getDoubleClickMinimizes()->bool:
	return self._settingsFile.get_value("Settings", "DoubleClickMinimizes", true)

func setDoubleClickMinimizes(value: bool)->void:
	self._settingsFile.set_value("Settings", "DoubleClickMinimizes", value)
	self.saveSettings()

	
# gets the dB value via the passed 0-100
# value (ranges from -60db (muted) to 0dB (normal))
static func parse_audio_level(value: float):
	return range_lerp(value, 0, 100, -60, 0)	

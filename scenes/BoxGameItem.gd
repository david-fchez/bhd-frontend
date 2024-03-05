extends Control
class_name BoxGameItem

func get_class():
	return "BoxGameItem"

func is_class(value):
	return value == "BoxGameItem"
	

var box: BoxInfo
var isSelected: bool = false

onready var boxName = $Hbox/Vbox/Name
onready var fee = $Hbox/Vbox/Fee
onready var status = $Hbox/Vbox/Status
onready var players = $Hbox/Vbox2/Players
onready var reward = $Hbox/Vbox2/Reward
onready var checkBtn = $Hbox/Vbox2/VB/CheckBtn

signal boxSelected(boxId) # emits when box is selected for entry
signal boxChecked(checked, boxId) # emits when box is checked for selection

func _ready():
	update_data(box)
	

# populate box data, optional
# bool value handles new icon
func update_data(box: BoxInfo, removeNew: bool = false):
	
	boxName.text = box.Name
	fee.text = Global.Wallet.displayCurrency(box.EntryFee)
	
	var st = BoxInfo.parse_status(box.Status).substr(0,1)	
	status.bbcode_text = color_status(st) + st + "[/color]"
	
	players.text = str(box.PlayerCount) + "/" + str(box.MaxPlayerCount) + " (" + str(box.MinPlayerCount) + ")"
	reward.text = Global.Wallet.displayCurrency(box.Reward)
	
	var isJoined = Global.joinedBoxes.find(box.BoxId) != -1

	if removeNew or isJoined:
		$NewIcon.hide()
	
	# remove checkbtn if box is not open and joined
	if (box.Status != BoxInfo.BoxStatusOpen and box.Status != BoxInfo.BoxStatusWarmup) \
		and !isJoined:
		$Hbox/Vbox2/VB/CheckBtn.hide()
		$Hbox/Vbox2/VB/Spacer.show()
	
	if isJoined:
		mark_as_joined()

# get the color for bbcode format
func color_status(status: String):
	if status == "O":
		return "[color=#39b54a]" #green
	elif "W" in status:
		return "[color=#f7931d]" #orange
	else:
		return "[color=#0093ff]" #default blue


# update status label
func update_status(value: String):
	status.bbcode_text = color_status(value) + value + "[/color]"


# mark as joined (pressed and disabled)
# since that texture is defined
func mark_as_joined():
	checkBtn.pressed = true
	checkBtn.disabled = true


# changes currency
func change_currency():
	reward.text = Global.Wallet.displayCurrency(box.Reward)
	fee.text = Global.Wallet.displayCurrency(box.EntryFee)


# mark as (un)selected
func check_box(pressed: bool):
	emit_signal("boxChecked", pressed, self.box.BoxId, self.isSelected)


# on clicked emit signal which the
# boxgameitem in game list is connected to
func _on_Hbox_gui_input(event):
	
	# scroll, dont join
	if event is InputEventScreenDrag:
		if event.speed.y < -0.2:
			print("swipe up")
			self.get_tree().set_input_as_handled()
			return
		elif event.speed.y > 0.2:
			print("swipe down")
			self.get_tree().set_input_as_handled()
			return
	elif event is InputEventScreenTouch:
		if event.is_pressed():
			mark_box()
	elif event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		if event.is_pressed():
			mark_box()


func mark_box():
	self.isSelected = true
	emit_signal("boxSelected", box.BoxId)

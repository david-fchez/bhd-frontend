extends Control

var selectedItem: TreeItem
var boxes: Array
var confirmResult: bool # for confirm dialog
var response: BoxJoinResponse
var imgTexture: ImageTexture
var checkedTexture: ImageTexture
var checkedGreenTexture: ImageTexture
var uncheckedTexture: ImageTexture
var emptyTexture: ImageTexture
var timerDictionary: Dictionary = {} # contains the durations
var timers: Dictionary = {} # contains the timers
var boxChildren: Dictionary = {} # holds the boxes by boxId key in mutable state
var checkedBoxes: Array # array of BoxIds that are checked
var newBoxes: Array # array of BoxIds that have the 'New' icon
var sortData: Dictionary = {Global.TreeColumns.STATUS_SHORT:true, Global.TreeColumns.BOX_NAME:true, Global.TreeColumns.PLAYERS:true, Global.TreeColumns.STAKE:true, Global.TreeColumns.REWARD:true} #holds the tree sort info: colIndex: isAscending
var root: TreeItem


onready var img = preload("res://assets/images/new.png")
onready var checked = preload("res://assets/images/checkbox.png")
onready var checkedGreen = preload("res://assets/images/checkbox_green.png")
onready var unchecked = preload("res://assets/images/checkbox-empty.png")
onready var empty = preload("res://assets/images/empty.png")

onready var tree: Tree = $Vbox/CC/Tree
onready var vbox: VBoxContainer = $Vbox/ScrollContainer/Vbox
onready var emptyLabel: Label = $Vbox/EmptyLabel
onready var cc: CenterContainer = $Vbox/CC
onready var scrollContainer: ScrollContainer = $Vbox/ScrollContainer
onready var sortBtns: HBoxContainer = $Vbox/SortBtns


func _ready():
	create_image()
	get_boxes()
	connect_to_signals()
	init_view()
	
# refreshes the view
func refresh_view(clearTimers: bool = true):
	clear_view(clearTimers)
	get_boxes()
	init_view(clearTimers)
	

# will clear the view - dictionaries
# and the Tree or ScrollContainer
func clear_view(clearTimers: bool = true):
	if clearTimers:
		timerDictionary.clear()
		timers.clear()
		checkedBoxes.clear()
	
	boxChildren.clear()
	
	# removes all instanced children
	if Global.IsPortrait:
		for n in vbox.get_children():
			vbox.remove_child(n)
			n.queue_free()
	# clear whole tree
	else:
		tree.clear()
		


# Fetch box games
func get_boxes()->void:
	boxes = Global.Game.getBoxes()
	
# detect portrait or landscape mode,
# show initial table view or 
# scroll container with box games
func init_view(clearTimers: bool = true)->void:
	# hide table, show scroll container
	if Global.IsPortrait:
		cc.hide()
		scrollContainer.show()
		sortBtns.show()
		$Vbox.add_constant_override("separation", 125)
		
		if boxes.size() > 0:
			for n in boxes.size():
				add_box(boxes[n], clearTimers)
		else:
			sortBtns.hide()
			emptyLabel.show()	
			
	# hide sc, show table
	else:
		scrollContainer.hide()
		cc.show()
		root = tree.create_item()
		tree.set_hide_root(true)
		if boxes.size() > 0:
			for n in boxes.size():
				add_box(boxes[n], clearTimers)
		else:
			tree.hide()
			emptyLabel.show()	

# Updates the view for the passed box
func update_box(box: BoxInfo = null)->void:
	
	# in portrait mode, update differently
	if Global.IsPortrait:
		if boxChildren.has(box.BoxId) and boxChildren[box.BoxId] != null \
		and boxChildren[box.BoxId].get_class() == "BoxGameItem":
			var instance = boxChildren[box.BoxId] as BoxGameItem
			instance.update_data(box)			
			check_timer(box)
			check_status(box)
			vbox.hide()
			vbox.show()
			return
	
	var child: TreeItem = boxChildren[box.BoxId]
	
	child.set_text(Global.TreeColumns.STATUS_SHORT, "(" + BoxInfo.parse_status(box.Status).substr(0,1) + ") ")
	child.set_tooltip(Global.TreeColumns.STATUS_SHORT, BoxInfo.parse_status(box.Status))
	child.set_text(Global.TreeColumns.BOX_NAME, box.Name)
	child.set_text(Global.TreeColumns.PLAYERS, str(box.PlayerCount) + "/" + str(box.MaxPlayerCount) + " (" + str(box.MinPlayerCount) + ") ")
	child.set_text(Global.TreeColumns.STAKE, Global.Wallet.displayCurrency(box.EntryFee))
	child.set_text(Global.TreeColumns.REWARD, Global.Wallet.displayCurrency(box.Reward))
	
	# handling 'New' icon
	if boxChildren.has(box.BoxId):
		child.set_text(Global.TreeColumns.NEW_ICON, "")
		newBoxes.erase(box.BoxId)
	else:
		if box.Status == BoxInfo.BoxStatusOpen:
			child.set_text(Global.TreeColumns.NEW_ICON, "NEW")
			child.set_custom_color(Global.TreeColumns.NEW_ICON, Color("ffffff"))
			newBoxes.append(box.BoxId)
	
	TreeHelper.color_status(child,box)	
	check_timer(box)
	check_status(box, child)

# adds a box to the tree and
# builds the child TreeItem
func add_box(box: BoxInfo, addNewIcon: bool = true)->void:
	# if in global mode, fill and return (dont fill Tree)
	if Global.IsPortrait and box != null and box.BoxId != null:
		var boxGameItem = load("res://scenes/BoxGameItem.tscn")
		var instance = boxGameItem.instance()
		instance.box = box
		instance.connect("boxSelected", self, "try_join_box")
		instance.connect("boxChecked", self, "update_selection")
		vbox.add_child(instance)	
		if boxChildren != null:
			boxChildren[box.BoxId] = instance
		check_status(box)
		vbox.hide()
		vbox.show()
		return
	
	if not tree.visible:
		tree.show()
		emptyLabel.hide()
		
	var child = tree.create_item(root)
	
	TreeHelper.build_column_headers(tree)

	# build cells
	child.set_text(Global.TreeColumns.STATUS_SHORT, "(" + BoxInfo.parse_status(box.Status).substr(0,1) + ") ")
	child.set_tooltip(Global.TreeColumns.STATUS_SHORT, BoxInfo.parse_status(box.Status))
	child.set_text(Global.TreeColumns.BOX_NAME, box.Name)
	child.set_text(Global.TreeColumns.PLAYERS, str(box.PlayerCount) + "/" + str(box.MaxPlayerCount) + " (" + str(box.MinPlayerCount) + ") ")
	child.set_text(Global.TreeColumns.STAKE, Global.Wallet.displayCurrency(box.EntryFee))
	child.set_text(Global.TreeColumns.REWARD, Global.Wallet.displayCurrency(box.Reward))

	TreeHelper.color_status(child,box)
	
	if addNewIcon and Global.joinedBoxes.find(box.BoxId) == -1:
		newBoxes.append(box.BoxId)
	
	if newBoxes.find(box.BoxId) != -1:
		if box.Status == BoxInfo.BoxStatusOpen:
			child.set_text(Global.TreeColumns.NEW_ICON, "NEW")
			child.set_custom_color(Global.TreeColumns.NEW_ICON, Color("ffffff"))
	else:
		child.set_text(Global.TreeColumns.NEW_ICON, "")
		
	
	# check texture - set checked, joined or
	# empty depending on box state
	if checkedBoxes.find(box.BoxId) != -1:
		child.add_button(Global.TreeColumns.CHECK_ICON, checkedTexture)
	elif Global.joinedBoxes.find(box.BoxId) != -1:
		child.add_button(Global.TreeColumns.CHECK_ICON, checkedGreenTexture)
	else:
		child.add_button(Global.TreeColumns.CHECK_ICON, uncheckedTexture)
	
	child.set_metadata(Global.TreeColumns.STATUS_SHORT, box.BoxId) # store the boxId in metadata of 0th column

	# alignment
	TreeHelper.align_cells(child)
	
	boxChildren[box.BoxId] = child
	check_timer(box)
	check_status(box, child)
	
# removes the box from the view
func remove_box(box: BoxInfo)->void:
	# if the player joined the box, dont remove it on
	# this signal, rather when result (win/loss) arrives
	if Global.joinedBoxes.has(box.BoxId):
		return
	
	if not Global.IsPortrait:
		root.remove_child(boxChildren[box.BoxId])
	else:		
		# find child via boxId key as index and free
		# since remove_child does not actually remove it
#		vbox.get_child(boxChildren.keys().find(box.BoxId)).visible = false
#		vbox.get_child(boxChildren.keys().find(box.BoxId)).free()
#		if boxChildren.has(box.BoxId) and boxChildren[box.BoxId] != null:
		var instance = boxChildren[box.BoxId] as BoxGameItem
		instance.visible = false
		instance.queue_free()
		vbox.hide()
		vbox.show()
	
	boxChildren.erase(box.BoxId)
	
	newBoxes.erase(box.BoxId)
	
	checkedBoxes.erase(box.BoxId)


# Connect to box-based signals to update their state
func connect_to_signals()->void:
	Global.Game.connect("onBoxDelete", self, "remove_box")
	Global.Game.connect("onBoxClose", self, "update_box")
	Global.Game.connect("onBoxSimulationStart", self, "update_box")
	Global.Game.connect("onBoxUpdate", self, "update_box")
	Global.Game.connect("onNewBox", self, "add_box") 
	Global.Game.connect("onBoxRefresh", self, "refresh_view")
	Global.Game.connect("onPlayerWon", self, "delete_from_view") 
	Global.Game.connect("onPlayerLoose", self, "delete_from_view") 
	ConfirmDialog.connect("popup_hide", self, "handle_confirmation")
	$StatusBar.connect("currencyChanged", self, "change_currency")


# removes the joined box from view
# request is type BoxShowWinnerRequest or BoxShowLooserRequest
# and has BoxId property always
func delete_from_view(request):
	if not Global.IsPortrait:
		root.remove_child(boxChildren[request.BoxId])
	else:		
		# find child via boxId key as index and free
		# since remove_child does not actually remove it
		var instance = boxChildren[request.BoxId] as BoxGameItem
		instance.visible = false
		instance.queue_free()
		vbox.hide()
		vbox.show()
	
	boxChildren.erase(request.BoxId)
	
	newBoxes.erase(request.BoxId)
	
	checkedBoxes.erase(request.BoxId)

# iterate over the tree children
# and set currency to changed type
# when the currency label is clicked/tapped
func change_currency():
	if root != null:
		var child = root.get_children()
		while child != null:			
			# find the box in cache via ID stored in metadata
			var box = Global.Game._boxCache.findElement("BoxId", child.get_metadata(Global.TreeColumns.STATUS_SHORT)) as BoxInfo
			
			child.set_text(Global.TreeColumns.STAKE, Global.Wallet.displayCurrency(box.EntryFee))
			child.set_text(Global.TreeColumns.REWARD, Global.Wallet.displayCurrency(box.Reward))
			
			child = child.get_next()
	
	# portrait mode
	elif Global.IsPortrait and boxChildren.size() > 0:
		for item in boxChildren.values():
			var gameItem = item as BoxGameItem
			gameItem.change_currency()
	

func _on_CancelButton_pressed():
	get_tree().change_scene(Global.MainMenu)


# Logic when game is selected
# Will have boxId passed if in portrait mode
# as its connected to a signal
func try_join_box(boxId = null):
	
	# Get the boxId
	if boxId == null:
		selectedItem = tree.get_selected()
		boxId = selectedItem.get_metadata(Global.TreeColumns.STATUS_SHORT) # has metadata set to boxid
	
	if Global.joinedBoxes.has(boxId):
		check_if_joined(boxId)
		return
	
	response = Global.Game.joinBox(boxId) 
	
	# If everything is valid on BC, continue
	if response != null and response.JoinAllowed == true:
		
		# Raise dialog
		var text = "You are about to join the box game. The fee is [color=white] %s SAT (%s BCH)[/color]. Confirm?"
		var formattedMsg = text % [str(response.EntryFeeSat), str(response.EntryFeeBch)]
		ConfirmDialog.confirmationMessage = formattedMsg
		ConfirmDialog.popup_centered()
	else:
		uncheck_box(boxId)			
		if response == null:
			pass # error showing in joinBox method
		else:
			Global.GameState.ErrorOutput(response.Info)
			

# Navigate if confrim dialog was confirmed
# otherwise exit box
func handle_confirmation()->void:
	# to prevent unexpected behaviour
	if ConfirmDialog.isQuitConfirmation:
		return
	
	if ConfirmDialog.confirmed:
		if !Global.IsPortrait:
			# different logic when selected in Tree or checked
			if selectedItem != null:
				sign_transaction(true)
			else:
				sign_transaction(false)
		else:
			var boxGame = boxChildren[response.BoxId] as BoxGameItem
			# if selected, that means the checkbox isn't pressed
			# and the actual item is pressed so navigate
			if boxGame.isSelected:
				sign_transaction(true)
			else:	
				sign_transaction(false)
		
	else:
		# if not confirmed remove check
		if Global.IsPortrait:
			var boxGame = boxChildren[response.BoxId] as BoxGameItem
			boxGame.isSelected = false
			boxGame.checkBtn.pressed = false
			
		Global.Game.exitBox()	

# Sign the TX and enter the box
# switchScene true if single box joining
func sign_transaction(switchScene: bool = false):
	var signedTx = Global.Wallet.signTransaction(response.Transaction)
	if signedTx != null:
		# noPlay is true if called from List without navigation to pregame
		var enterRequest = Global.Game.enterBox(signedTx, !switchScene)
		if enterRequest != null:
			if enterRequest.Info != "":
				Global.GameState.ErrorOutput(enterRequest.Info)
				return
			# TODO - check enterRequest.EntryAllowed?
			
			# mark as joined
			if not Global.IsPortrait:
				var child: TreeItem = boxChildren[enterRequest.BoxId]
				child.erase_button(Global.TreeColumns.CHECK_ICON, 0)
				child.add_button(Global.TreeColumns.CHECK_ICON, checkedGreenTexture) 
			else:
				var child: BoxGameItem = boxChildren[enterRequest.BoxId]
				child.mark_as_joined()
				
			Global.joinedBoxes.append(enterRequest.BoxId)
			
			# remove box from dictionary
			checkedBoxes.erase(enterRequest.BoxId)

			
			# change scene if not multi-box join
			if switchScene:
				get_tree().change_scene(Global.PreGame)


# checks box status to hide check
# button, different for portrait/landscape
# and child will be passed in landscape mode
func check_status(box: BoxInfo, child: TreeItem = null):
	
	# check if box is joined to hide btn
	if Global.joinedBoxes.has(box.BoxId):
		checkedBoxes.erase(box.BoxId)
			
	if box.Status != BoxInfo.BoxStatusOpen:
		checkedBoxes.erase(box.BoxId)
		
		if not Global.IsPortrait:
			# find the box to remove check if box is not joined to by player
			if boxChildren.has(box.BoxId) and boxChildren[box.BoxId] != null and \
			!Global.joinedBoxes.has(box.BoxId) and box.Status != BoxInfo.BoxStatusWarmup:
				if child.get_button_by_id(Global.TreeColumns.CHECK_ICON, 0) != -1:
					child.erase_button(Global.TreeColumns.CHECK_ICON, 0)
					
					# add dummy texture so vertical separation isn't messed up
					child.add_button(Global.TreeColumns.CHECK_ICON, emptyTexture, -1, true) 


# will check if the timer
# needs to be fired to
# show warmup countdown
func check_timer(box: BoxInfo):

	# if in Warmup mode and if timer is not already running
	if box.Status == BoxInfo.BoxStatusWarmup and !timerDictionary.has(box.BoxId):
		# set the duration from which to countdown
		timerDictionary[box.BoxId] = box.WarmupCountdown

		# create timer that will countdown
		var timer = Timer.new()
		add_child(timer)
		timer.autostart = true
		timer.one_shot = false
		timer.wait_time = 1
		# update remaining countdown
		timer.connect("timeout", self, "update_timer", [box])
		timer.start()
		
		timers[box.BoxId] = timer

	
# checks the timer dictionary and updates
# the remaining countdown time	
func update_timer(box: BoxInfo):
	if timerDictionary != null and timerDictionary[box.BoxId] != null:
		var value = timerDictionary[box.BoxId]
		timerDictionary[box.BoxId] = int(value) - 1
		
		# check dictionary
		if boxChildren.has(box.BoxId) and boxChildren[box.BoxId] != null:
			if Global.IsPortrait:
				var boxGameItem: BoxGameItem = boxChildren[box.BoxId]
				boxGameItem.update_status(str("W " + str(value) +" ") if value > 0 else "W")
			else:
				boxChildren[box.BoxId].set_text(Global.TreeColumns.STATUS_SHORT, (str("(W " + str(value) +") ") if value > 0 else "(W) "))
		
		# stop timer
		if value < 1:
			timers[box.BoxId].stop()
			return


# create imgTexture from image
func create_image():
	imgTexture = ImageTexture.new()
	checkedTexture = ImageTexture.new()
	checkedGreenTexture = ImageTexture.new()
	uncheckedTexture = ImageTexture.new()
	emptyTexture = ImageTexture.new()
	
	imgTexture.create_from_image(img.get_data())
	checkedTexture.create_from_image(checked.get_data())
	checkedGreenTexture.create_from_image(checkedGreen.get_data())
	uncheckedTexture.create_from_image(unchecked.get_data())
	emptyTexture.create_from_image(empty.get_data())


# sort by pressed col index
func _on_Tree_column_title_pressed(column):
	match column:
		Global.TreeColumns.STATUS_SHORT:
			sort_games(column, "Status")
		Global.TreeColumns.BOX_NAME:
			sort_games(column, "Name")
		Global.TreeColumns.PLAYERS:
			sort_games(column, "PlayerCount")
		Global.TreeColumns.STAKE:
			sort_games(column, "EntryFee")
		Global.TreeColumns.REWARD:
			sort_games(column, "Reward")


# sort games by pressed colIndex and property,
# also connected to by SortBtns for portrait mode
func sort_games(column: int, property: String):
	if sortData[column] == true:
		Global.Game._boxCache.sortDescending(property)
	else:
		Global.Game._boxCache.sortAscending(property)
		
	sortData[column] = !sortData[column]
	refresh_view(false)


func _on_Tree_button_pressed(item: TreeItem, column: int, id: int):
	
	# (un)check btn
	if column == Global.TreeColumns.CHECK_ICON and item != null:
		# get child and remove/add it as (un)checked
		var child: TreeItem = boxChildren[item.get_metadata(Global.TreeColumns.STATUS_SHORT)]
		var boxId = item.get_metadata(Global.TreeColumns.STATUS_SHORT)
		
		# if box already joined, ignore
		if Global.joinedBoxes.has(boxId):
			return
		
		if Global.SettingsManager.getAutoEnterBox():
			join_box(boxId)
		else:
			try_join_box(boxId)
		
		

# used in portrait mode, to
# handle  box checking	
func update_selection(pressed: bool, boxId: String, isSelected: bool):
	if !isSelected and pressed and !Global.joinedBoxes.has(boxId):
		checkedBoxes.append(boxId)
		if Global.SettingsManager.getAutoEnterBox():
			join_box(boxId)
		else:
			try_join_box(boxId)
		


# joins selected boxes
func join_box(boxId: String):	
	
	if Global.joinedBoxes.has(boxId):
		check_if_joined(boxId)
		return

	response = Global.Game.joinBox(boxId) 
	# If everything is valid on BC, continue
	if response != null and response.JoinAllowed == true:
		sign_transaction()
	else:
		uncheck_box(boxId)		
		if response == null:
			pass
		else:
			Global.GameState.ErrorOutput(response.Info)
					

# used in Portrait, to set icon as unchecked
# on unsuccessful join box
func uncheck_box(boxId: String):
	if Global.IsPortrait:
		var boxGame = boxChildren[boxId] as BoxGameItem
		boxGame.checkBtn.pressed = false
		checkedBoxes.erase(boxId)


# just navigate to pregame w 
# found box
func check_if_joined(boxId: String):
	if Global.joinedBoxes.has(boxId):
		var list = Global.Game.getBoxes() 
		Global.Game._playersBox = list[boxes.find(boxId)]
		get_tree().change_scene(Global.PreGame)
		return

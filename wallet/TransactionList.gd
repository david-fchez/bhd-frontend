extends Control

const SENSITIVITY = 15

var imgTexture: ImageTexture
var list: GetTransactionsResponse
var pageSize: int = 5 # the page size for the tree
var page: int = 1 # current page
var skip: int = 0 # current skip number
var sortData: Dictionary = {1: true, 2: true, 3: true, 4: true, 5: true} # sort data -> col: ascending

onready var tree: Tree = $Vbox/CC/Tree
onready var img = preload("res://assets/images/copy.png")

# check for swipe events on mobile to change page
func _unhandled_input(event):
	if event is InputEventScreenDrag:
		var swipe = event.relative
		if swipe.x < SENSITIVITY and not $Vbox/Hbox/PreviousBtn.disabled:
			_on_PreviousBtn_pressed()
		elif swipe.x > SENSITIVITY and not $Vbox/Hbox/NextBtn.disabled:
			_on_NextBtn_pressed()

# get the Txs on ready
func _ready():
	create_image()
	list = Global.Wallet.getTransactions([Global.PlayerInfo.BchAddress], pageSize, skip)
	build_tree()
	$StatusBar.connect("currencyChanged", self, "change_currency")
	$Vbox/Hbox.size_flags_horizontal = SIZE_SHRINK_CENTER if Global.IsPortrait else SIZE_FILL

# get the tree root, and iterate
# over it to change the currency
# while getting the original value from the list
func change_currency():
	if tree.get_root() != null:
		var child = tree.get_root().get_children()
		while child != null:
			# get the original tx from the list
			var tx = list.transactions.findElement("Hash", child.get_text(1))
			
			child.set_text(2, Global.Wallet.displayCurrency(tx.InputVal))
			child.set_text(3, Global.Wallet.displayCurrency(tx.OutputVal))
			child.set_text(4, Global.Wallet.displayCurrency(tx.CashBack))
			
			child = child.get_next()


# refresh tree data starting from the skip entry
# if Previous btn is pressed, need to subtract the page numer
# so the skip updates accordingly
func refresh_data(fromPrevious: bool = false):
	tree.get_root().free()
	skip = (page if !fromPrevious else page - 1) * pageSize
	list = Global.Wallet.getTransactions([Global.PlayerInfo.BchAddress], pageSize, skip)
	build_tree()
	
	# if there are exact number of tx as the pageSize, or
	# there are less tx than the page size, or
	# the page is last (skip + pagesize == totalLength), disable Next
	if list.transactions.size() < pageSize \
	 or (list.transactions.size() == pageSize and list.transactionCount == pageSize) \
	 or list.transactionCount <= pageSize \
	 or list.transactionCount == (pageSize + skip):
		$Vbox/Hbox/NextBtn.disabled = true
	else:
		$Vbox/Hbox/NextBtn.disabled = false
	
# fill data	
func build_tree():
	var root = tree.create_item()
	tree.set_hide_root(true)
	
	# in portrait mode, make Tree smaller
	if Global.IsPortrait:
		var xSize = round(get_viewport().size.x * 0.75)
		tree.rect_min_size = Vector2(xSize, 700)
		$Vbox.add_constant_override("separation", 100)
	
	if list != null and list.transactions != null and list.transactions.size() > 0:
		show_tree()

		# if there are exact number of tx as the pageSize, or
		# there are less tx than the page size disable Next
		if (list.transactions.size() == pageSize and list.transactionCount == pageSize) \
		or list.transactionCount <= pageSize:
			$Vbox/Hbox/NextBtn.disabled = true
		
		# if skip is 0 we're on start
		$Vbox/Hbox/PreviousBtn.disabled = true if skip == 0 else false	
		
		for n in list.transactions.size():
			var child: TreeItem = tree.create_item(root)
			var tx = list.transactions.asArray()[n] as Tx
			
			# build col headers
			tree.set_column_title(1, "Hash")
			tree.set_column_title(2, "Input")
			tree.set_column_title(3, "Output")
			tree.set_column_title(4, "Cashback")
			tree.set_column_title(5, "Time")
			tree.set_column_title(0, "")
			tree.set_column_expand(0, true)
			tree.set_column_min_width(0, 54)
			tree.set_column_min_width(1, 200)
			tree.set_column_min_width(2, 200)
			tree.set_column_min_width(3, 200)
			tree.set_column_min_width(4, 200)	
			tree.set_column_min_width(5, 225)
			
			child.add_button(0, imgTexture)
			child.set_text(1, tx.Hash)
			child.set_text(2, Global.Wallet.displayCurrency(tx.InputVal))
			child.set_text(3, Global.Wallet.displayCurrency(tx.OutputVal))
			child.set_text(4, Global.Wallet.displayCurrency(tx.CashBack))
			child.set_text(5, Time.get_datetime_string_from_datetime_dict(Time.get_date_dict_from_unix_time(tx.DateTime), true).substr(0, 16))
			
			
			# alignment
			child.set_text_align(0, TreeItem.ALIGN_LEFT)
			child.set_text_align(1, TreeItem.ALIGN_CENTER)
			child.set_text_align(2, TreeItem.ALIGN_CENTER)
			child.set_text_align(3, TreeItem.ALIGN_CENTER)
			child.set_text_align(4, TreeItem.ALIGN_CENTER)
			child.set_text_align(5, TreeItem.ALIGN_CENTER)
	else:
		hide_tree()	
		

# show empty label for empty tree and hide buttons
func hide_tree():
	tree.hide()
	$Vbox/CC/EmptyLabel.show()	
	$Vbox/Hbox/PreviousBtn.hide()
	$Vbox/Hbox/NextBtn.hide()

# show Tree if not empty and buttons too
func show_tree():	
	tree.show()
	$Vbox/CC/EmptyLabel.hide()	
	$Vbox/Hbox/PreviousBtn.show()
	$Vbox/Hbox/NextBtn.show()
	
func create_image():
	imgTexture = ImageTexture.new()
	imgTexture.create_from_image(img.get_data())	

func _on_BackButton_pressed():
	get_tree().change_scene(Global.PreviousScene)

# copy hash to clipboard and show 'Copied!' label for 1s
func _on_Tree_button_pressed(item: TreeItem, column, id):	
	$CopiedLabel.show()
	OS.set_clipboard(item.get_text(1)) # get the hash which is second col in tree
	yield(get_tree().create_timer(1.0), "timeout")
	$CopiedLabel.hide()

# update page number
func _on_NextBtn_pressed():
	if page >= 1: 
		refresh_data()
		page += 1
		

# update page number
func _on_PreviousBtn_pressed():
	if page > 0:
		page -= 1
		refresh_data(true)
		

# handle col title press for sort
func _on_Tree_column_title_pressed(column):
	match column:
		1:
			sort_data(1, "Hash")
		2:
			sort_data(2, "InputVal")
		3:
			sort_data(3, "OutputVal")
		4:
			sort_data(4, "CashBack")
		5:
			sort_data(5, "DateTime")
		_:
			return

# sort the list by given prop, refresh tree
func sort_data(column: int, property: String):
	if sortData[column]:
		list.transactions.sortDescending(property)
	else:
		list.transactions.sortAscending(property)
		
	sortData[column] = !sortData[column]
	tree.get_root().free()
	build_tree()

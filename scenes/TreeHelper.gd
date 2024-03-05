# contains helper methods for Tree node
class_name TreeHelper


# colors the status column depending on box status
static func color_status(child: TreeItem, box: BoxInfo):
	if box.Status == BoxInfo.BoxStatusWarmup:
		child.set_custom_color(Global.TreeColumns.STATUS_SHORT, Color("f7931d")) # match 'New' icon color
	elif box.Status == BoxInfo.BoxStatusOpen:
		child.set_custom_color(Global.TreeColumns.STATUS_SHORT, Color("39b54a")) # match status bar light color
	else:
		child.set_custom_color(Global.TreeColumns.STATUS_SHORT, Color("0093ff")) # default blue color


# build column titles, width and expansion logic
static func build_column_headers(tree: Tree):
	tree.set_column_title(Global.TreeColumns.STATUS_SHORT, "")
	tree.set_column_title(Global.TreeColumns.BOX_NAME, "Name")
	tree.set_column_title(Global.TreeColumns.PLAYERS, "Players")
	tree.set_column_title(Global.TreeColumns.STAKE, "Stake")
	tree.set_column_title(Global.TreeColumns.REWARD, "Reward")
	tree.set_column_title(Global.TreeColumns.NEW_ICON, "")
	tree.set_column_title(Global.TreeColumns.CHECK_ICON, "")
	
	tree.set_column_expand(Global.TreeColumns.STATUS_SHORT, true)
	tree.set_column_expand(Global.TreeColumns.NEW_ICON, true)
	tree.set_column_expand(Global.TreeColumns.CHECK_ICON, true)
	
	tree.set_column_min_width(Global.TreeColumns.STATUS_SHORT, 90)
	tree.set_column_min_width(Global.TreeColumns.BOX_NAME, 250)
	tree.set_column_min_width(Global.TreeColumns.PLAYERS, 200)
	tree.set_column_min_width(Global.TreeColumns.STAKE, 200)
	tree.set_column_min_width(Global.TreeColumns.REWARD, 200)
	tree.set_column_min_width(Global.TreeColumns.NEW_ICON, 75)	
	tree.set_column_min_width(Global.TreeColumns.CHECK_ICON, 75)


# align the child TreeItem
static func align_cells(child: TreeItem):
	child.set_text_align(Global.TreeColumns.STATUS_SHORT, TreeItem.ALIGN_CENTER)
	child.set_text_align(Global.TreeColumns.BOX_NAME, TreeItem.ALIGN_CENTER)
	child.set_text_align(Global.TreeColumns.PLAYERS, TreeItem.ALIGN_CENTER)
	child.set_text_align(Global.TreeColumns.STAKE, TreeItem.ALIGN_CENTER)
	child.set_text_align(Global.TreeColumns.REWARD, TreeItem.ALIGN_CENTER)
	child.set_text_align(Global.TreeColumns.NEW_ICON, TreeItem.ALIGN_CENTER)
	child.set_text_align(Global.TreeColumns.CHECK_ICON, TreeItem.ALIGN_CENTER)

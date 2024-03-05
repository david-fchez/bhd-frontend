extends CanvasLayer


var snacks: Array = [] # array of BoxShowWinnerRequest or BoxShowLoserRequest to show in queue


# show the snack and populate labels
func _display_snack(request):
	show()
	var isWinner = "PayoutBchAddress" in request # check if property exists
	
	$Control/TextureRect/Vbox/Message.text = request.BoxName + "\r\n" \
	+ ("Won" if isWinner else "Lost") + ("\r\n" if isWinner else "") \
	+ ((str(request.TotalRewardSat) + " SAT (" + str(request.TotalRewardBch) + " BCH)") if isWinner else "") 
	$Timer.start()

# adds snack/request to (potentially) show
func add_snack(request):
	snacks.append(request)
	if visible and $Timer.time_left > 0:
		yield(get_tree().create_timer($Timer.time_left), "timeout")
		_display_snack(request)
	else:
		_display_snack(request)


#remove snack, hide view
func _on_Timer_timeout():
	snacks.remove(0)
	hide()

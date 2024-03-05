extends Popup

var texture1 = preload("res://assets/images/you-win-1.png")
var texture2 = preload("res://assets/images/you-win-2.png")
var firstImgTexture: ImageTexture
var secondImgTexture: ImageTexture
var isWinner: bool
var request # type BoxShowWinnerRequest or BoxShowLoserRequest

var _firstAssetVisible: bool

# init dialog with data
func _on_GameResult_about_to_show():
	$Bg/WinnerBox.hide()
	$Bg/LoserBox.hide()
	
	if isWinner:
		_firstAssetVisible = true
		build_textures()
		$Bg/WinnerBox.show()
		
		if request != null:
			$Bg/WinnerBox/Header.text = request.BoxName + "\n" + str(request.TotalRewardSat) + " SAT (" + str(request.TotalRewardBch) + " BCH)" 
		$Timer.start()
	else:
		$Bg/LoserBox.show()
		if request != null:
			$Bg/LoserBox/Header.text = request.BoxName
	
# set Winner image flickering
func _on_Timer_timeout():
	if _firstAssetVisible:
		$Bg/WinnerBox/TextureRect.texture = secondImgTexture
		_firstAssetVisible = false
	else:
		$Bg/WinnerBox/TextureRect.texture = firstImgTexture
		_firstAssetVisible = true

# init textures for winner popup type
func build_textures():
	firstImgTexture = ImageTexture.new()
	secondImgTexture = ImageTexture.new()
	
	firstImgTexture.create_from_image(texture1.get_data())
	secondImgTexture.create_from_image(texture2.get_data())
	
	
func _on_CloseButton_pressed():
	hide()

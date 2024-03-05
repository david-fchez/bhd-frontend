extends Control

func _ready():
	check_layout()
	
	$VBox/HBox/Address.text = Global.PlayerInfo.BchAddress
	
	# void create_from_data ( int width, int height, bool use_mipmaps, Format format, PoolByteArray data )
	var qrCodeSize = 255
	var imageData: PoolByteArray = Global.Wallet.getQrCode(Global.PlayerInfo.BchAddress, qrCodeSize)
	if imageData.size() == 0:
		return
	var img = Image.new()
	img.load_png_from_buffer(imageData)
	yield(get_tree(), "idle_frame")
	var imgTexture = ImageTexture.new()
	imgTexture.create_from_image(img,0)
	$VBox/QRcode.texture = imgTexture
	
	scale_ui()
	

func scale_ui():
	if Global.IsPortrait:
		var scale = Vector2(1, 1.2)
		$VBox/Label.rect_scale = scale
		$VBox/HBox.rect_scale = scale
		$VBox/CenterContainer.rect_scale = scale

	
# according to layout, set params
func check_layout():
	$VBox.add_constant_override("separation", 120 if Global.IsPortrait else 35)
	$VBox/Label.set_autowrap(true if Global.IsPortrait else false)
	$VBox/HBox/Address.set_autowrap(true if Global.IsPortrait else false)

func _on_Back_pressed():
	get_tree().change_scene(Global.MainMenu)


# copy address, show Copied!
func _on_Copy_pressed():
	#$CopiedLabel.show()
	OS.set_clipboard($VBox/HBox/Address.text)
	#yield(get_tree().create_timer(1.0), "timeout")
	#$CopiedLabel.hide()

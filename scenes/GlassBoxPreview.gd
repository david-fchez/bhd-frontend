extends Spatial


func _ready():
	pass


func getDirection()->Vector3:
	return $ArrowGimbal.Heading

extends Spatial

var hasEmitted = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func emitEffect():
	$Particles.emitting = true
	hasEmitted = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if hasEmitted and !$Particles.emitting:
		queue_free()

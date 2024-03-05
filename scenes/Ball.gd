extends RigidBody

onready var wallCollisionSound : AudioStreamOGGVorbis = preload("res://assets/audio/gameplay/impactGlass_heavy_001.ogg")
onready var ballCollisionSound : AudioStreamOGGVorbis = preload("res://assets/audio/gameplay/impactMetal_heavy_004.ogg")

var glassBox

#var health : float = 10.0

var isPlayer = false
var itemName: String
var guid: String
var initPos: Vector3
var initVelocity: Vector3
var isReplay = false
var events: Array
var eventIndex: int = 0
var prevEvent: position
var nextEvent: position


func _ready():
	glassBox = get_tree().get_root().find_node("GlassBox", true, false)
	
	#why would the default be true? how implemented this in Godot
	wallCollisionSound.loop = false
	ballCollisionSound.loop = false
	
	##if events.empty(): $HealthBar3D.hide() # hide HP bar if in preview mode

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	#for replay mode
	if isReplay and glassBox.currentBallCount > 1:
		self.linear_velocity = Vector3(0,0,0)
		#get current frame absolute value
		var currentFrame = Engine.get_physics_frames() - glassBox.firstFrame
		
		#find prev and next event and interpolate position
		if(eventIndex == 0): 
			nextEvent = events[eventIndex]
			var t :float = clamp(( float(currentFrame) - 0.000 ) / ( float(nextEvent.frame) - 0.000 ), 0.000, 1.000 )
			#print("t:", t, " currFrm: ", currentFrame, " nextFrm: ", nextEvent.frame, " delta: ", delta)
			#var interpolatedPos = hermite_spline(t, initPos, nextEvent.location, initVelocity, initVelocity)
			#var interpolatedPos = hermite_interpolate(ease(t, -0.8), initPos, nextEvent.location, initVelocity, initVelocity, delta)
			#var interpolatedPos = hermite_interpolate(smoothstep(0, 1, t), initPos, nextEvent.location, initVelocity, initVelocity, delta)
			#var interpolatedPos = hermite(t, initPos, nextEvent.location, initVelocity, nextEvent.velocity)
			#var interpolatedPos = lerp(initPos, nextEvent.location, t)
			var interpolatedPos = lerp(initPos, nextEvent.location, ease(t, 1))
			#self.global_transform.origin = interpolatedPos
			#self.transform.origin = interpolatedPos#lerp(initPos, nextEvent.location, t)
			#print("	interPos: ", interpolatedPos, " init: ", initPos, " next: ", nextEvent.location)
			self.set_translation(interpolatedPos)
			pass
		elif (eventIndex > 0 and eventIndex <= events.size()-1):
			#print("ev index ", eventIndex)
			prevEvent = events[eventIndex-1]
			nextEvent = events[eventIndex]
			var t:float = clamp(( float(currentFrame) - float(prevEvent.frame) ) / ( float(nextEvent.frame) - float(prevEvent.frame)+0.00000000000001 ), 0.000, 1.000 )
			#print("t:", t, " currFrm: ", currentFrame, " prevFrm: ", prevEvent.frame, " nextFrm: ", nextEvent.frame, " delta: ", delta)
			#var interpolatedPos = hermite_spline(t, prevEvent.location, nextEvent.location, prevEvent.velocity, prevEvent.velocity)
			#var interpolatedPos = hermite_interpolate(ease(t, -0.8), prevEvent.location, nextEvent.location, prevEvent.velocity, prevEvent.velocity, delta)
			#var interpolatedPos = hermite_interpolate(smoothstep(0, 1, t), prevEvent.location, nextEvent.location, prevEvent.velocity, prevEvent.velocity, delta)
			#var interpolatedPos = hermite(t, self.get_translation(), nextEvent.location, prevEvent.velocity, nextEvent.velocity)
			#var interpolatedPos = lerp(prevEvent.location, nextEvent.location, t)
			var interpolatedPos = lerp(prevEvent.location, nextEvent.location, ease(t, 1))
			#self.global_transform.origin = interpolatedPos
			#self.transform.origin = interpolatedPos#lerpPos
			#print("	interPos: ", interpolatedPos, " init: ", prevEvent.location, " next: ", nextEvent.location)
			self.set_translation(interpolatedPos)
			pass
		else:
			#this shouldn't be the case, after the last event you either won or you are dead
			if stepify(self.scale.x, 0.01) <= stepify(glassBox.minScale, 0.01):
				#print("kill ball")
				glassBox.updateBallCount(-1)
				if $EffectPlayer.is_playing():
					glassBox.soundCounter -= 1
				self.queue_free()
			pass
		
		#check if current event is now or in past
		if(currentFrame >= nextEvent.frame):
			if eventIndex > events.size()-1:
				glassBox.updateBallCount(-1)
				if $EffectPlayer.is_playing():
					glassBox.soundCounter -= 1
				self.queue_free()
			
			#print(self.name,  " : ",currentFrame, "	|	", nextEvent.frame, "	|	", eventIndex,  "	|	", events.size())
			handleHealth(nextEvent)
			
			#play collisionSounds
			if glassBox.soundCounter < glassBox.maxSoundEffect and !$EffectPlayer.is_playing():
				glassBox.soundCounter += 1
				if nextEvent.isHit:
					$EffectPlayer.set_stream(ballCollisionSound)
					$EffectPlayer.play()
				else:
					$EffectPlayer.set_stream(wallCollisionSound)
					$EffectPlayer.play()
			
			eventIndex = eventIndex + 1
			#print("this is hit :", eventIndex)
		pass


#handle health and effects for replay round
#only working in replay mode
func handleHealth(event):
	#print("handle called	", health, "|", nextEvent.health, " HIT: ", event.isHit)
	if stepify(event.scale, 0.01) >= stepify(self.scale.x, 0.01) and event.isHit:
		self.scale = Vector3(event.scale, event.scale, event.scale)
		glassBox.spawnEffect(isPlayer, self.global_transform.origin, self.scale)
	elif stepify(event.scale, 0.01) < stepify(self.scale.x, 0.01) and event.isHit:
		self.scale = Vector3(event.scale, event.scale, event.scale)
	
	#health = event.health
	if stepify(self.scale.x, 0.01) <= stepify(glassBox.minScale, 0.01):
		glassBox.updateBallCount(-1)
		if $EffectPlayer.is_playing():
			glassBox.soundCounter -= 1
		self.queue_free()

#this is a collision
#only working in simulaiton mode
func _on_Ball_body_entered(body):
	pass


#basic interpolation method, like lerp() in gdScript but maybe better
func lerp_vector(v1: Vector3, v2: Vector3, alpha:float)->Vector3:
	return v1 * alpha + v2 * (1.0 - alpha)

# don't touch this function, it's magic
func hermite_spline(t: float, p0: Vector3, p1: Vector3, t0: Vector3, t1: Vector3)->Vector3:
	var t2: float = pow(t, 2)
	var t3: float = pow(t, 3)
	var h1: float =  2*t3 - 3*t2 + 1
	var h2: float = -2*t3 + 3*t2
	var h3: float =    t3 - 2*t2 + t
	var h4: float =    t3 - t2
	return h1*p0 + h2*p1 + h3*t0 + h4*t1

# Given an object in TWO frames, below is the hermite cubic interpolation between frames.
# The four pieces of information is you need is:
# t = 0 to 1
# dt = delta time
# tickA position (p1)
# tickB position (p2)
# tickA velocity (v1)
# tickB velocity (v2)
func hermite_interpolate(t: float, p1: Vector3, p2: Vector3, v1: Vector3, v2: Vector3, dt: float) -> Vector3:
	var t2: float = pow(t, 2)
	var t3: float = pow(t, 3)
	var a: float = 1 - 3*t2 + 2*t3
	var b: float = t2 * (3 - 2*t)
	var c: float = dt * t * pow(t - 1, 2)
	var d: float = dt * t2 * (t - 1)
	return (a * p1) + (b * p2) + (c * v1) + (d * v2)

#yet another version of the interpolation alg
func hermite(t: float, p1: Vector3, p2: Vector3, v1: Vector3, v2: Vector3)->Vector3:
	var t2: float = pow(t, 2)
	var t3: float = pow(t, 3)
	var a: float = 1 - 3*t2 + 2*t3
	var b: float = t2 * (3 - 2*t)
	var c: float = t * pow(t - 1, 2)
	var d: float = t2 * (t - 1)
	return a * p1 + b * p2 + c * v1 + d * v2


#when sound ends, decrease the collisionSound counter
func _on_EffectPlayer_finished():
	glassBox.soundCounter -= 1

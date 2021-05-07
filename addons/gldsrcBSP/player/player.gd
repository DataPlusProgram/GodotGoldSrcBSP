extends KinematicBody

export var speed = 15
var mouseSensitivity = 0.05
var direction = Vector3()
var accHor = Vector3()
var hp = 100
var dead = false
export var gravity = 1
export(NodePath) var bspNodePath = null
var jumpSpeed = 0.5

var initalGravity = gravity
var gravityVelo = Vector3()
var onGround = false
var jumpSound = false
onready var colShape = $"CollisionShape"
onready var camera = $"Camera"
onready var footCast = $"footCast"
onready var initialShapeDim = Vector2(colShape.shape.radius,colShape.shape.height)
onready var lastStep = translation
onready var lastMat = "-"
onready var footstepSound = $"footstepSound"
onready var bspNode = get_node(bspNodePath)
onready var shootCast = $"Camera/shootCast"

var footStepDict = {
	"C":["player/pl_step1.wav","player/pl_step2.wav"],
	"M":["player/pl_metal1.wav","player/pl_metal2.wav"],
	"D":["player/pl_dirt1.wav","player/pl_dirt2.wav","player/pl_dirt3.wav"],
	"V":["player/pl_duct1.wav"],
	"G":["player/pl_grate1.wav","player/pl_grate4.wav"],
	"T":["player/pl_tile1.wav","player/pl_tile2.wav","player/pl_tile3.wav","player/pl_tile4.wav"],
	"S":["player/pl_slosh1.wav","player/pl_slosh2.wav","player/pl_slosh3.wav","player/pl_slosh4.wav"],
	"W":["debris/wood1.wav","debris/wood2.wav","debris/wood3.wav"],
	"P":["debris/glass1.wav","debris/glass2.wav","debris/glass3.wav"],
	"Y":["debris/glass1.wav","debris/glass2.wav","debris/glass3.wav"],
	"F":["weapons/bullet_hit1.wav","weapons/bullet_hit1.wav","weapons/bullet_hit1.wav"]
	

}

var cachedSounds = {}

func _ready():
	var err = bspNode.connect("playerSpawnSignal",self,"setSpawn")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event):
	if dead:
		return
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouseSensitivity))
		camera.rotate_x(deg2rad(-event.relative.y * mouseSensitivity))
		camera.rotation.x = clamp(camera.rotation.x, deg2rad(-89),deg2rad(89))

func _physics_process(delta):
	#cameraStuff()
	onGround = is_on_floor()
	if hp == 0:
		die()
		
		
	var collider = footCast.get_collider()
	if collider != null:
		onGround = true
	#print(onGround)
	shoot()
	footsteps()
	direction = Vector3.ZERO
	
	if !onGround:
		gravityVelo += Vector3.DOWN * gravity * delta
	else:
		gravityVelo = -get_floor_normal() * 0.01
	
	
	
	if Input.is_action_just_pressed("ui_accept") and onGround:
		gravityVelo = Vector3.UP * jumpSpeed
		var mat = getFootMaterial()
		if mat!=null:
			playMatStepSound(mat)
		
		
	
	if Input.is_action_pressed("ui_up"):
		direction -= transform.basis.z
	elif Input.is_action_pressed("ui_down"):
		direction += transform.basis.z
		
	if Input.is_action_pressed("ui_left"):
		direction -= transform.basis.x
	elif Input.is_action_pressed("ui_right"):
		direction += transform.basis.x
	
	if Input.is_action_just_pressed("crouch"):
		colShape.shape.radius = initialShapeDim.x * 0.25
		colShape.shape.height = initialShapeDim.y * 0.25
	
	if Input.is_action_just_released("crouch"):
		colShape.shape.radius = initialShapeDim.x 
		colShape.shape.height = initialShapeDim.y
	
	direction = direction.normalized()
	if dead:
		direction = Vector3.ZERO
		

	direction += gravityVelo
	move_and_slide(direction*speed,Vector3.UP,false,4,0.758,false)
	
	for index in get_slide_count():
		var collision = get_slide_collision(index)
	
		if collision.collider.get_class() == "RigidBody":
			collision.collider.apply_central_impulse(-collision.normal * 1)
	
	
func setSpawn(dict):
	#print(dict)
	translation = dict["pos"]
	rotation_degrees.y = dict["rot"]+90

	
	
func enterLadder():
	print("player enter ladder")
	gravity = -initalGravity
	
func exitLadder():
	print("player exit ladder")
	gravity = initalGravity

func die():
	if dead:
		return
	camera.rotate_z(deg2rad(90))
	dead = true
	colShape.shape.radius = initialShapeDim.x * 0.01
	colShape.shape.height = initialShapeDim.y * 0.01
	return

func footsteps():
	
	if direction.length() < 0.1 and jumpSound == false:
		return
		
	var collider = footCast.get_collider()
	if collider == null:
		return
	
	var matType = getFootMaterial()
	
	if matType == null:
		return
	
	
	
	if footStepDict.has(matType):
		if translation.distance_to(lastStep) < 2 and lastMat == matType:  
			lastMat = matType
			return
		
		lastMat = matType
		lastStep = translation
		
		playMatStepSound(matType)


func getFootMaterial():
	var collider = footCast.get_collider()
	if collider == null:
		return null
	
	if collider.has_meta("materialType"):
		var matType = collider.get_meta("materialType")
		return matType
	else:
		return null
		
func playMatStepSound(mat):
	if footStepDict.has(mat):
		var randomIndex = randi()%footStepDict[mat].size()
		
		var soundFilePath = footStepDict[mat][randomIndex]
		var stream = null
		if !cachedSounds.has(soundFilePath):
			cachedSounds[soundFilePath] = bspNode.loadSound(soundFilePath)
			
		stream = cachedSounds[soundFilePath]
		
		if footstepSound.playing == false:
			footstepSound.stream = stream
				
			footstepSound.play()
		
	
func shoot():
	return
	var collider = shootCast.get_collider()
	if collider == null:
		return

	
	
	if Input.is_action_just_pressed("shoot"):
		direction -= transform.basis.z
		var ap = AudioStreamPlayer.new()
		ap.stream = bspNode.loadSound("weapons/pl_gun3.wav")
		ap.volume_db*= 0.005
		add_child(ap)
		ap.play()
		
		if collider.has_meta("breakable"):
			var breakNode = collider.get_meta("breakable")
			breakNode.takeDamage()
		if collider.has_method("takeDamage"):
			collider.takeDamage
		
func cameraStuff():
	var ninety  = deg2rad(90)
	var rotY = rotation.y + ninety
	#LineDraw.drawLine(translation,translation+Vector3(cos(rotY),0,-sin(rotY))*10)#
	
	
	var x = cos(rotY)*cos(camera.rotation.x)
	var y = sin(camera.rotation.x)
	var z = -sin(rotY)*cos(camera.rotation.x)
	
	var origin = translation
	#LineDraw.drawLine(origin,origin+Vector3(x,y,z)*100)#
	

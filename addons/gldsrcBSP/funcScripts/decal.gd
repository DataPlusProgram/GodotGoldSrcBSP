extends Sprite3D



var flag = true
var ready = false
var tickWait = 0
func _ready():
	ready = true
	get_node("Area/CollisionShape").shape.radius = 0.10
	
	pass # Replace with function body.


func _physics_process(delta):
	if tickWait == 3:
		checkCasts()
		get_node("Area").queue_free()
	tickWait+=1
	

	
func checkCasts():
	var closest = {"object":null,"distance":INF,"contactNormal":Vector3.ZERO}
	var area  : KinematicBody= get_node("Area")
	var collision = area.move_and_collide(Vector3.ZERO)
	if collision!= null:
		var collider = collision.collider
		if collider.get_node_or_null("face0"):
			var face = collider.get_node("face0")
			var meta = face.get_meta("normal")
			var v1 = Vector3(0,0,1)
			var v2 = collision.normal
			var ang = acos(v1.dot(v2))
			var rotAxis = v1.cross(v2).normalized()
			rotate(rotAxis.normalized(),ang)
			translation += collision.normal*0.01
		else:
			queue_free()
	else:
		queue_free()


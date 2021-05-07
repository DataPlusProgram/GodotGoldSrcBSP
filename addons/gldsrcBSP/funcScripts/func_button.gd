extends Area


var targetNodes
var targetName = ""
var sound 
var timer = null
var cooldown = false
func _ready():
	
	targetName = get_meta("target")
	sound = get_node_or_null("sound")
	
	
func _physics_process(delta):
	if cooldown == true:
		return
		
	for c in get_overlapping_bodies():
		if c.is_in_group("hlTrigger"):
			cooldown = true
			if sound != null:
				sound.play()
			if targetName != null:
				toggle()
		
			if timer == null:
				timer = Timer.new()
				timer.wait_time = 1.5
				timer.connect("timeout", self, "coolDownOver")
				add_child(timer)
				timer.start()

func setState(state):
	toggle()

func toggle():
	
	for i in get_tree().get_nodes_in_group(targetName):
		if "locked" in i:
			i.locked = false
		i.toggle()

func coolDownOver():
	cooldown = false
	timer.queue_free()
	timer = null

extends Area


var mapName

func _ready():
	mapName = get_meta("mapName").to_lower()


func _process(delta):
	for i in get_overlapping_bodies():
		if i.is_in_group("hlTrigger"):
			get_tree().call_group("worldManager","changeMap",mapName)


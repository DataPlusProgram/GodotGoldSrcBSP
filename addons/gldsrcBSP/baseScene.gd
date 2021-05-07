extends Spatial


func changeMap(strName):
	
	#$"BSP_Map".queue_free()
	var dir : String = $"BSP_Map".path.replace("\\","//")
	var listeners = $"BSP_Map".get_signal_connection_list("playerSpawnSignal")
	remove_child($"BSP_Map")
	var bspMap = load("res://addons/gldsrcBSP/BSP_Map.tscn").instance()
	
	
	
	dir = dir.substr(0,dir.find_last("/"))
	#var dir = $"BSP_Map".path.find_last("\")
	bspMap.path = dir + "/" + strName + ".bsp"
	bspMap.name = "BSP_Map"
	add_child(bspMap)
	
	for l in listeners:
		bspMap.connect("playerSpawnSignal",l["target"],"setSpawn")
	
	bspMap.loadBSP()

tool
extends EditorPlugin


var pluginDock

var curSlectedNode = null

func _enter_tree():
	add_custom_type("GLDSRC_Map","Spatial",load("res://addons/gldsrcBSP/src/BSP_Map.gd"),null) 
	pluginDock = load("res://addons/gldsrcBSP/pluginToolbar.tscn").instance()
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,pluginDock)
	
	pluginDock.get_node("createMapButton").connect("pressed", self, "createMap")
	pluginDock.visible = false

func _exit_tree():
	remove_custom_type("createMapButton")
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU,pluginDock)

func make_visible(visible: bool) -> void:
	if pluginDock:
		pluginDock.set_visible(visible)

func handles(object):
	return object is GLDSRC_Map 
	
func edit(object):
	curSlectedNode = object
	
func createMap():
	curSlectedNode.createMap()
	recursiveOwn(curSlectedNode,get_tree().edited_scene_root)
	

func recursiveOwn(node,newOwner):
	for i in node.get_children():
		if !i.has_meta("hidden"):
			recursiveOwn(i,newOwner)
	
	node.owner = newOwner

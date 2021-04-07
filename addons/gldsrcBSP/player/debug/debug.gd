extends VBoxContainer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	$"fps".text = "fps:" + str(Engine.get_frames_per_second())
	$"drawCalls".text = "draw calls:" + str(Performance.get_monitor(Performance.RENDER_DRAW_CALLS_IN_FRAME))
	$"vertices".text = "vertices:" + str(Performance.get_monitor(Performance.RENDER_VERTICES_IN_FRAME))
	$"material".text = "materials:" + str(Performance.get_monitor(Performance.RENDER_MATERIAL_CHANGES_IN_FRAME))

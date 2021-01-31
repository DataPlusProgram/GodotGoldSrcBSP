extends AudioStreamPlayer3D

func activate():
	if !playing:
		play()

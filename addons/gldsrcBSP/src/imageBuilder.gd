tool
extends Node

func _ready():
	set_meta("hidden",true)
	
func createImage(fileDict,isDecal = false,imageDictParam = null):#imageDictParam is used when the texture is within the BSP itself instead of external WAD
	var imageDict
	if imageDictParam == null:
		imageDict = parseTexture(fileDict["file"],fileDict["offset"],fileDict["size"])
	else:
		imageDict = imageDictParam
		
	if !imageDict.has("data"):
		return
		
	var data = imageDict["data"]
	
	var pallete = imageDict["palette"]
	#var isDecal = imageDict["name"][0] == "{" and isDecal
	var w = imageDict["dim"][0]
	var h = imageDict["dim"][1]
	var image = Image.new()
	image.create(w,h,false,Image.FORMAT_RGBA8)
	image.lock()
	
	
	for y in h:
		for x in w:
			var colorIndex = data[x+(y*w)]
			if isDecal == false:
				var color = pallete[colorIndex]
				image.set_pixel(x,y,color)
			else:
				var color = pallete[colorIndex]
				var baseColor = pallete[pallete.size()-1]
				image.set_pixel(x,y,Color8(baseColor.r,baseColor.g,baseColor.b,1))
			
	
	image.unlock()
	
	var texture = ImageTexture.new()
	
	
	
	texture.create_from_image(image)
	if !get_parent().textureFiltering:
		texture.flags -= texture.FLAG_FILTER
	return texture
	
func parseTexture(file,offset,size):
	var textureDict = {}
	
	file.seek(offset)
	
	textureDict["name"] = file.get_String(16)
	var w =  file.get_32()
	var h =  file.get_32()
	var mip1 = file.get_32u()
	var mip2 =  file.get_32u()
	var mip3 = file.get_32u()
	var mip4 =  file.get_32u()
	
	var mip1sz = mip2 - mip1
	var mip4sz = mip1sz / 64
	
	file.seek(mip1+offset)
	
	var data = []
	var pallete = []
		
	for p in (w*h):
		data.append(file.get_8())
		
	file.seek(mip4+offset+mip4sz+2)
		
	for c in 256:
		var r = file.get_8() / 255.0
		var g = file.get_8() / 255.0
		var b = file.get_8() / 255.0
		if r== 0 and g == 0 and b== 1:
			pallete.append(Color(0,0,0,0))
		else:
			pallete.append(Color(r,g,b))
	
	textureDict["dim"] = [w,h]
	textureDict["data"] = data
	textureDict["palette"] = pallete
	
	#get_parent().imageBuilder.createImage(textureDict)
	return textureDict
	
func createImageFromName(txtureName):
	for t in get_parent().textures:
		if t.name == txtureName:
			breakpoint

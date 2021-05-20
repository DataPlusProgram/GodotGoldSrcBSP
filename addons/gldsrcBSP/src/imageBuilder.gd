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
	var image : Image = Image.new()
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
				image.set_pixel(x,y,Color(baseColor.r,baseColor.g,baseColor.b,1-color.r))
	
#	var RGBA : PoolByteArray = []
	#RGBA.resize(w*h*4)
	#var count = 0
	
	#for y in h:
	#	for x in w:
	#		var colorIndex = data[x+(y*w)]
	#		if isDecal == false:
	#			var color = pallete[colorIndex]
	#			RGBA[count] = color.r*255
	#			RGBA[count+1] = color.g*255
	#			RGBA[count+2] = color.b*255
#				RGBA[count+3] = color.a*255
	#			count += 4
	
	#image.create_from_data(w,h,false,image.FORMAT_RGBA8,RGBA)

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
			
func createImageArrFromSpr(path): 
	
	var file = load("res://addons/gldsrcBSP/DFile.gd").new()
	file.loadFile(path)
	var magic = file.get_String(4)
	var version = file.get_32()
	var spriteType = file.get_32()
	var textureFormat = file.get_32()
	var boundingRdadious = file.get_float32()
	var maxW = file.get_32()
	var maxH = file.get_32()
	var numFrames = file.get_32()
	var beamLen = file.get_float32()
	var syncType = file.get_32()
	
	var sizeOfPalette = file.get_16()
	var pallete = []
	for c in sizeOfPalette:
			var r = file.get_8() / 255.0
			var g = file.get_8() / 255.0
			var b = file.get_8() / 255.0
			pallete.append(Color(r,g,b,1))
	
	var retImages = []
	
	for i in numFrames:
		var frameGroup = file.get_32()
		var frameOriginX = file.get_32()
		var frameOriginY = file.get_32()
		var frameW = file.get_32()
		var frameH = file.get_32()
		
		var w = frameW
		var h = frameH
		var image : Image = Image.new()
		image.create(w,h,false,Image.FORMAT_RGBA8)
		image.lock()
		var lan = file.get_len()
		var data = file.get_buffer(w*h)
		
		for y in h:
			for x in w:
				var colorIndex = data[x+(y*w)]
				var color = pallete[colorIndex]
				image.set_pixel(x,y,color)

		retImages.append(image)
		
	return retImages

func createTextureFromSpr(path):
	
		
	var imgArr = createImageArrFromSpr(path)
	var texture = AnimatedTexture.new()
	texture.frames = imgArr.size()
	
	for i in imgArr.size():
		var frame = ImageTexture.new()
		frame.create_from_image(imgArr[i])
		texture.set_frame_texture(i,frame)
	
	
	return texture

tool
extends Node


var file
var fileDict = {}
var colorTable = []

func _ready():
	set_meta("hidden",true)

func getImageFromBMP(path,rotate = false):
	fileDict = {}
	colorTable = []
	
	file = load("res://addons/gldsrcBSP/DFile.gd").new()
	if !file.loadFile(path):
		print("bmp file not found:" + path)
		return Image.new()
	
	fileDict["magic"] = file.get_String(2)
	fileDict["fileSize"] = file.get_32()
	fileDict["reserved"] = file.get_32()
	fileDict["data offset"] = file.get_32()
	
	parseInfoHeader()
	parseColorTable()
	var img = parseData(rotate)

	return img

func createTextureFromBMP(path):
	var img = getImageFromBMP(path)
	var texture = ImageTexture.new()
	texture.create_from_image(img)

	return texture
func parseInfoHeader():
	fileDict["infoHeaderSize"] = file.get_32()
	fileDict["width"] = file.get_32()
	fileDict["height"] = file.get_32()
	fileDict["plane"] = file.get_16()
	fileDict["bitCount"] = file.get_16()
	fileDict["Compression"] = file.get_32()
	fileDict["ImageSize"] = file.get_32()
	fileDict["XpixelsPerM"] = file.get_32()
	fileDict["YpixelsPerM"] = file.get_32()
	fileDict["colorsUsed"] = file.get_32()
	fileDict["colorsImportant"] = file.get_32()
	if fileDict["colorsUsed"] == 0:
		fileDict["colorsUsed"] = 256
	print(fileDict["colorsImportant"])
func parseColorTable():
	var colorTableSize = fileDict["colorsUsed"]
	for i in colorTableSize:
		var b = file.get_8()
		var g = file.get_8()
		var r = file.get_8()
	
		var _unused = file.get_8()
		

		colorTable.append(Color8(r,g,b))
		
	
func parseData(rotate):
	file.seek(fileDict["data offset"])
	var image = Image.new()
	
	var width = fileDict["width"]
	var height =  fileDict["height"]
	
	image.create(width,height,true,Image.FORMAT_RGB8)
	image.lock()
	
	for x in width:
		for y in height:
			var index = file.get_8()
			var color = colorTable[index]
			if rotate == false:
				image.set_pixel(y,width-1-x,color)
			else:
				image.set_pixel(width-1-x,height-y-1,color)
			
	image.unlock()
	return image


func stitchImages(left,front,right,back,top,bottom):
	var panImage = Image.new()
	panImage.create(256*4,256*3,true,Image.FORMAT_RGB8)
	panImage.lock()
	var sourceRect = Rect2(Vector2(0,0),Vector2(256,256))
	panImage.blend_rect(left,sourceRect,Vector2(0,256))
	panImage.blend_rect(front,sourceRect,Vector2(256,256))
	panImage.blend_rect(right,sourceRect,Vector2(512,256))
	panImage.blend_rect(back,sourceRect,Vector2(768,256))
	
	panImage.blend_rect(top,sourceRect,Vector2(256,0))
	panImage.blend_rect(bottom,sourceRect,Vector2(256,512))
	return panImage
	

tool
extends Node

var curLineY = 0
var curLineMaxH = 0
var allLineMaxH = 0
var image : Image
var maxW = 800
var curPos = Vector2(0,0)
var texture : ImageTexture
var faceToOrigLM = {}
var atlasImgDimArr = []
var atlasImgDimArrImg = []
var atlasPos = []
var atlasDim  = []

# Called when the node enters the scene tree for the first time.
func _ready():
	image = Image.new()
	image.create(maxW,10,true,Image.FORMAT_RGB8)
	texture = ImageTexture.new()
	set_meta("hidden",true)
	#texture.flags = 0
	

func addToAtlas(fmap,index = 1):
	#fmap.save_png("lightMaps/"+String(index)+".png")
	var dim = fmap.get_size()
	var mapSize = image.get_size()
	
	#print(mapSize)
	if (curPos.x + dim.x) > maxW:
		curPos.y+=curLineMaxH
		curLineMaxH = 0
		curPos.x=0
		
	if dim.y > curLineMaxH: curLineMaxH = dim.y

	var localRect = Rect2(Vector2.ZERO,dim)
	
	if curPos.y + dim.y > image.get_size().y:
		image.crop(maxW,curPos.y + dim.y)
	
	image.blit_rect(fmap,localRect,Vector2(curPos.x,curPos.y))
	curPos.x += dim.x
	return Vector2(curPos-Vector2(dim.x,0))


func addToAtlas2(fmap,index = 1):
	var dim = fmap.get_size()
	atlasImgDimArr.append(dim)
	atlasImgDimArrImg.append(fmap)

func getSize():
	return image.get_size()

func getTexture():
	texture.create_from_image(image)
	#texture.flags = 0
	return texture

func initAtlas():
	var atlasArr =Geometry.make_atlas(atlasImgDimArr)
	atlasPos = atlasArr["points"]
	atlasDim = atlasArr["size"]
	
	image = Image.new()
	image.create(atlasDim.x,atlasDim.y,true,Image.FORMAT_RGB8)
	texture = ImageTexture.new()
	#texture.flags = 0
	
	
	for i in atlasImgDimArr.size():
		var source = Rect2(Vector2.ZERO,atlasImgDimArrImg[i].get_size())
		image.blit_rect(atlasImgDimArrImg[i],source,atlasPos[i])
		
	
	#return {"rectArr":atlasArr}
	#for f in atlasImgDimArrImg:
		
	#image.crop(maxW,curPos.y + dim.y)
	#for i in atla
	#image.resize(image.get_size().x,image.get_size().y,Image.INTERPOLATE_TRILINEAR)
	texture.create_from_image(image)
	#texture.flags = 0
	
	image.save_png("atlas.png")
	
	
	
	
	return {"texture":texture,"rects":atlasArr}


func saveToFile():
	texture.set_data(image)
	#texture.flags = 0
	image.save_png("atlas.png")

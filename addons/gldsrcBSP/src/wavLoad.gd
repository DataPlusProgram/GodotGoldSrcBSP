tool
extends Node



var file
var fileDict = {}


func _ready():
	set_meta("hidden",true)


func getStreamFromWAV(path):
	file = load("res://addons/gldsrcBSP/DFile.gd").new()
	
	if !file.loadFile(path):
		print("audio file not found:" + path)
		return AudioStreamSample.new()
		
	fileDict["magic"] = file.get_String(4)
	fileDict["chunkSize"] = file.get_32()
	fileDict["format"] = file.get_String(4)
	
	parseFmt()
	file.seek(fileDict["dataChunkOffset"])
	parseData()
	var stream = createStream()
	var pos = file.get_position()
	var chunkId = file.get_String(4)
	
	
	if chunkId == "LIST":
		parseList()
	
	var cueArr = []
	if !file.eof_reached():
		chunkId = file.get_String(4)
		
		if chunkId == "CUE ":
			cueArr = parseCue()
	
	stream.loop_end = stream.data.size()
	
	if cueArr.size()>0:
		stream.loop_mode = AudioStreamSample.LOOP_FORWARD
		stream.loop_begin = cueArr[0]
		
	
	if cueArr.size()>1:
		stream.loop_end = cueArr[1]
	
	return stream
	



func parseFmt():
	fileDict["fmtId"] = file.get_32()
	fileDict["fmtSize"] = file.get_32()
	fileDict["dataChunkOffset"] = fileDict["fmtSize"] + file.get_position()
	fileDict["audioFormat"] = file.get_16()
	fileDict["numChannels"] = file.get_16()
	fileDict["sampleRate"] = file.get_32()
	fileDict["byteRate"] = file.get_32()
	fileDict["blocksAlign"] = file.get_16()
	fileDict["bitsPerSample"] = file.get_16()

func parseData():
	fileDict["dataId"] = file.get_String(4)
	fileDict["dataSize"] = file.get_32()
	
func createStream():
	var stream = AudioStreamSample.new()
	stream.mix_rate = fileDict["sampleRate"]
	if fileDict["numChannels"] > 1:
		stream.stereo = true
		
	if fileDict["bitsPerSample"] == 8: stream.format = AudioStreamSample.FORMAT_8_BITS
	if fileDict["bitsPerSample"] == 16: stream.format = AudioStreamSample.FORMAT_16_BITS
	
	var dataSize = fileDict["dataSize"]
	var data = []
	
	for i in range(0,dataSize):
		data.append((file.get_8()-128)/2.0)

	if !file.eof_reached():
		file.get_8()#all files that had another chunk after the data chunk had a single byte of padding
	stream.data = data
	return stream

func parseList():
	
	var listDict = {}
	listDict["dataSize"] = file.get_32()
	var endPos = file.get_position() + listDict["dataSize"]
	listDict["chunkType"] = file.get_String(4)
	file.seek(endPos)

func parseCue():
	var curDict = {}
	var cueOffsets = []
	curDict["dataSize"] = file.get_32()
	curDict["numCues"] = file.get_32()
	
	for n in curDict["numCues"]:
		curDict["id"] = file.get_32()
		curDict["position"] = file.get_32()
		curDict["fccChunk"] = file.get_32()
		curDict["chunkStart"] = file.get_32()
		curDict["blockStart"] = file.get_32()
		curDict["sampleOffset"] =file.get_32()
		cueOffsets.append(curDict["position"]/8)
	return cueOffsets
	

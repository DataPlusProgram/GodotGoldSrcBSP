tool
extends Spatial

#var faces = []
var edges
var surfEdges
var vertices
var planes
var textures
var textureInfos
var brushModels
var geometryParentNode = null
var edgeToFaceIndexMap
var renderables
var renderableEdges
#var workingFaceMeshNodes = {}
var linkedFacesDict = {}
var theFaceIndex = 0
var hotFaces
var renderModeFaces
var skyMat = null
var lightmapOffset = null
var cubeMapShader = preload("res://addons/gldsrcBSP/cubemap.shader")
var skyCubemap = null
var atlasTexture : ImageTexture
var atlasDim 
var kinematicBodies = false
var rads = {
	"+0~GENERIC65": Color(1,1,1),
	"+0~GENERIC85":Color(1,1,1),
	"+0~GENERIC86":Color(1,1,1),
	"+0~GENERIC86B":Color(1,1,1),
	"+0~GENERIC86R":Color(1,1,1),
	"GENERIC87A":Color(1,1,1),
	"GENERIC88A":Color(1,1,1),
	"GENERIC89A":Color(1,1,1),
	"GENERIC90A":Color(1,1,1),
	"GENERIC105":Color(1,1,1),
	"GENERIC106":Color(1,1,1),
	"GENERIC107":Color(1,1,1),
	"GEN_VEND1":Color(1,1,1),
	"EMERGLIGHT":Color(1,1,1),
	"~+0LAB1_W6D" : Color(1,1,1),
	"~+0LAB1_W6" : Color(1,1,1),
	"~+0LAB1_W7":Color(1,1,1),
	"SKKYLITE":Color(1,1,1),
	"~LIGHT2A" : Color(1,1,1),
	"~LIGHT3B" : Color(1,1,1),
	"~LIGHT3C" : Color(1,1,1),
	"~LIGHT5A" : Color(1,1,1),
	"~LIGHT5F" : Color(1,1,1),
	"+0~TNNL_LGT1" : Color(1,1,1),
	"+0~TNNL_LGT2" : Color(1,1,1),
	"+0~TNNL_LGT3" : Color(1,1,1),
	"+0~TNNL_LGT4" : Color(1,1,1),
	"~EMERGLIGHT":Color(1,1,1),
	"+0~FIFTS_LGHT01": Color(1,1,1),
	"+0~FIFTIES_LGT2": Color(1,1,1),
	"+0~FIFTS_LGHT4": Color(1,1,1),
	"+0~DRKMTLS1" : Color(1,1,1),
	"0~DRKMTLGT1" : Color(1,1,1),
	"+0~DRKMTLS2" : Color(1,1,1),
	"+0~DRKMTLS2C" : Color(1,1,1),
	"+0DRKMTL_SCRN" : Color(1,1,1),
	"+0~LAB_CRT8":Color(1,1,1),
	"RED":Color(1,0,0),
	"YELLOW":Color(1,1,0),
	"~SPOTYELLOW":Color(1,1,1),
	"+0~LIGHT2A":Color(1,1,1),
	"+A~FIFTS_LGHT4":Color(1,1,1)
	
	}



func _ready():
	set_meta("hidden",true)
	
	#mat.set_shader_param("cube_map",skyCubemap)

func createLevel(dict,wadDict):

	renderModeFaces = get_parent().renderModeFaces
	geometryParentNode = Spatial.new()
	geometryParentNode.name = "Geometry"
	get_parent().add_child(geometryParentNode)
	vertices = get_parent().vertices
	#faces = get_parent().faces
	surfEdges = get_parent().surfaces
	edges = get_parent().edges
	planes = get_parent().planes
	textureInfos = get_parent().textureInfo
	textures = get_parent().textures
	brushModels = get_parent().brushModels
	hotFaces = get_parent().hotFaces
	edgeToFaceIndexMap = get_parent().edgeToFaceIndexMap
	lightmapOffset = get_parent().ligthMapOffset
	#atlasTexture = get_parent().get_node("lightmapAtlas").getTexture()
	var a = OS.get_system_time_msecs()
	var atlasDict = get_parent().get_node("lightmapAtlas").initAtlas()
	atlasDim = get_parent().get_node("lightmapAtlas").getSize()
	atlasTexture = atlasDict["texture"]
	var atlasRects = atlasDict["rects"]
	
	if get_parent().optimize == true:
		#a = OS.get_system_time_msecs()
		generateEdgeTrackerFaces()
		#combineEdgeTracker()
		#print("Generate edge tracker faces:", OS.get_system_time_msecs()-a)
		mergeBrushModelFaces3()

	#a = OS.get_system_time_msecs()
	var renderables= get_parent().renderables
	
	for faceIdx in renderables.size():
		var face = renderables[faceIdx]
		if face.empty():
			continue
		var faceIndex = faceIdx#faces.find(face)
		var meshNode = null
		
		
		var fanMesh  = createMeshFromFanArr(face,faceIndex)
		
		if fanMesh != null:
			fanMesh.use_in_baked_light = true
			get_parent().faceMeshNodes[faceIndex] = fanMesh
			geometryParentNode.add_child(fanMesh)
			

	#get_parent().get_node("lightmapAtlas").saveToFile()
	
	a = OS.get_system_time_msecs()
	if get_parent().collisions == true:
		if get_parent().faceMeshNodes!= null:
			for f in get_parent().faceMeshNodes.values():
				if f != null:
					createCollisionsForMesh(f)
	else:
		for f in get_parent().faceMeshNodes.values():
			var newParent = Spatial.new()
			newParent.add_child(f)
			geometryParentNode.add_child(newParent)
			
	#print("collisions:",OS.get_system_time_msecs()-a)
	if get_parent().textureLights:
		textureLights()
	


func getCenter(vertices):
	var sum = Vector3.ZERO
	for i in vertices:
		sum += i

	return sum/vertices.size()

func getCenterFanArr(fans):
	var center= Vector3.ZERO
	var count = 0
	for textureName in fans:
		for i in fans[textureName]:
			center += getCenter(i["verts"])
			count += 1
		#	center += getCenter(fan["verts"])
			
	#		count +=1


	return center/count

func getCenter2d(vertices):
	var sum = Vector2.ZERO
	for i in vertices:
		sum += i

	return sum/vertices.size()

func fanMerge(fans):
	for textureName in fans:
		for fan in fans[textureName]:
			if fan != null:
				mergeAfan(fans,fan)


func mergeAfan(fans,fan1):
	for textureName in fans:
		for fan2 in fans[textureName]:
			#fan2 = fan2[textureName]
			if fan1["verts"] == null: continue
			if fan2["verts"] == null: continue

			if fan1 == fan2:
				continue
			if fan1["normal"] == fan2["normal"]:
				var comb = combineVerts(fan1["verts"],fan2["verts"])
				if comb != null:
					fan1["verts"] = comb
					fan2["verts"] = []



func getMatType(textureName):
	var lookupString  = textureName
	if lookupString.length() > 12:
		lookupString = lookupString.substr(0,12)
	
	lookupString = lookupString.trim_prefix("!")
	lookupString = lookupString.trim_prefix("~")
	lookupString = lookupString.trim_prefix("{")
	

	var matType = "C"
	if get_parent().textureToMaterialDict.has(lookupString):
		matType = get_parent().textureToMaterialDict[lookupString]

	return matType

#var surf : SurfaceTool = SurfaceTool.new()

func createMeshFromFanArr(fans,faceIndex):
	var center = getCenterFanArr(fans)
	var texture
	
	var surf: SurfaceTool = SurfaceTool.new()
	var runningMesh = ArrayMesh.new()

	var mat# : SpatialMaterial
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count = 0
	
	var atlasPosArr = get_parent().get_node("lightmapAtlas").atlasPos
	var atlasDimArr = get_parent().get_node("lightmapAtlas").atlasImgDimArr
	var matType = null #currently I'm only picking a mat at random this can fail for multi-material meshes
	for textureName in fans:
		var localSurf = SurfaceTool.new()
		if matType == null:
			matType = getMatType(textureName)
		texture = get_parent().fetchTexture(textureName)
		
		localSurf.set_material(mat)
		localSurf.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		var localLightmap
		
		for locFan in fans[textureName]:
			var fIdx = locFan["faceIndex"] 
			var triVerts = locFan["verts"]
			var triNormals = []
			var triUV = locFan["uv"]
			var vertsLocal = []
			localLightmap =locFan["localLightmap"]
			
			for i in triVerts:
				vertsLocal.append(i-center)
				triNormals.append(locFan["normal"])
			
			var lightmapUV = locFan["lightmapUV"]
			
			for i in triUV.size():
				triUV[i] /= texture.get_size()
			#	

			var atlasPos = atlasPosArr[fIdx]
			var dimInAtlas = atlasDimArr[fIdx]
			
			var mins = Vector2(INF,INF)
			var maxs = Vector2(-INF,-INF)
			var locDim = localLightmap.get_size() 
			
			for i in lightmapUV.size():
				if lightmapUV[i].x < mins.x : mins.x = lightmapUV[i].x
				if lightmapUV[i].x < mins.y : mins.y = lightmapUV[i].y
				
				if lightmapUV[i].x > maxs.x : maxs.x = lightmapUV[i].x
				if lightmapUV[i].y > maxs.y : maxs.y = lightmapUV[i].y
			#print(String(fIdx),":",lightmapUV)
			
			mins+=Vector2(1,1)/locDim
			maxs-=Vector2(1,1)/locDim
			
			for i in lightmapUV.size():
				lightmapUV[i].x = lerp(mins.x,maxs.x,lightmapUV[i].x)
				lightmapUV[i].y = lerp(mins.y,maxs.y,lightmapUV[i].y)
				
				lightmapUV[i]*=localLightmap.get_size() #convert to pixel
				lightmapUV[i] += atlasPosArr[fIdx]#shift over the position in the atlas
				lightmapUV[i] /= atlasDim#convert to 
				#lightmapUV[i] /= get_parent().scale_factor)

			if !get_parent().disableTextures:
				if textureName!="SKY":
					mat = createMat(texture,textureName,renderModeFaces)
				else:
					mat = createMatSky()
			
			localSurf.add_triangle_fan(vertsLocal,triUV,[],lightmapUV,triNormals)
			
		localSurf.commit(runningMesh)

		
		if mat!=null:
			if textureName!="SKY":
				mat.albedo_texture = texture
				if get_parent().importLightmaps:
					mat.detail_uv_layer = SpatialMaterial.DETAIL_UV_2
					mat.detail_enabled = true
					mat.detail_albedo = atlasTexture
					mat.detail_blend_mode = SpatialMaterial.BLEND_MODE_MUL
		
			runningMesh.surface_set_material(count,mat)
			runningMesh.surface_set_name(count,textureName)
		count+=1


	surf.commit(runningMesh)

	var meshNode = MeshInstance.new()
	meshNode.name = "face_mesh_" + String(faceIndex)
	meshNode.mesh = runningMesh
	
	get_parent().faceMeshNodes[faceIndex] = meshNode
	
	meshNode.translation = center
	
	meshNode.set_meta("textureName",fans.keys()[0])
	meshNode.set_meta("fans",fans)
	meshNode.set_meta("materialType",matType)
	if hotFaces.has(faceIndex):
		meshNode.set_meta("hotFace",true)
	return meshNode


func createMat(texture,textureName,render = null):


	var matCacheName = textureName# + String(texInfo["fSShift"]) + String(texInfo["fTShift"])# + String(texInfo["vS"]) + String(texInfo["vT"])

	var matDict = get_parent().fetchMaterial(matCacheName)
	var mat : SpatialMaterial = matDict["material"]



	if matDict["isFirstInstance"]:
		if texture != null:
			var textureDim = texture.get_size()
			mat.albedo_texture = texture

			if texture.get_data().detect_alpha() != 0:
				mat.flags_transparent =true
		#if rads.has(textureName):
			
		mat.flags_world_triplanar = true
		mat.emission_enabled = true
		#mat.emission_texture = 
		#mat.uv1_triplanar = true
		get_parent().saveToMaterialCache(matCacheName,mat)

	return(mat)

func createMatSky():
	
	if skyMat == null:
		var path = get_parent().skyTexture
		var bmpLoader = get_parent().get_node("bmpLoader")


		var left = loadTGAasImage(path + "lf.tga")
		var right = loadTGAasImage(path + "rt.tga")
		var bottom = loadTGAasImage(path + "dn.tga")
		var top = loadTGAasImage(path + "up.tga")
		var front = loadTGAasImage(path + "ft.tga")
		var back =  loadTGAasImage(path + "bk.tga")

		top = rotImage(top,"top")
		bottom = rotImage(bottom,"bottom")
		#var rect = Rect2(Vector2(-256,-256),Vector2(256,256))
		#top.blit_rect(top,rect,Vector2(256,256))
		skyCubemap = CubeMap.new()
		if get_parent().textureFilterSkyBox == false:
			skyCubemap.flags -= skyCubemap.FLAG_FILTER
		skyCubemap.set_side(0,left)
		skyCubemap.set_side(1,right)
		skyCubemap.set_side(2,bottom)
		skyCubemap.set_side(3,top)
		skyCubemap.set_side(4,front)
		skyCubemap.set_side(5,back)


		var mat = ShaderMaterial.new()
		mat.set_shader_param("cube_map",skyCubemap)
		mat.shader = cubeMapShader
		skyMat = mat

		return skyMat

	return(skyMat)




func createCollisionsForMesh(meshNode):
	
	#if meshNode.get_meta("textureName")[0]  == "!":
	#	return

	var center = meshNode.translation
	meshNode.translation = Vector3.ZERO
	if meshNode.get_meta("textureName")[0]  != "!":# and meshNode.has_meta("hotFace"):
		meshNode.create_trimesh_collision()
	else:
		meshNode.scale = Vector3(0.99,0.99,0.99)
		meshNode.create_convex_collision()


	meshNode.get_parent().remove_child(meshNode)
	var staticBodyNode = meshNode.get_child(0)

	if meshNode.has_meta("hotFace") and kinematicBodies:
		var shape = staticBodyNode.get_child(0)
		shape.get_parent().remove_child(shape)
		staticBodyNode.queue_free()
		staticBodyNode = KinematicBody.new()
		staticBodyNode.add_child(shape)
	
	if meshNode.get_meta("textureName")[0]  == "!":
		var shape = staticBodyNode.get_child(0)
		shape.get_parent().remove_child(shape)
		staticBodyNode.queue_free()
		staticBodyNode = Area.new()
		staticBodyNode.add_child(shape)
	
	meshNode.remove_child(staticBodyNode)
	meshNode.name = "face" + String(theFaceIndex)
	staticBodyNode.translation = center
	  
	if meshNode.get_meta("textureName")[0]  == "!":
		var scriptRes = load("res://addons/gldsrcBSP/funcScripts/water.gd")
		staticBodyNode.set_script(scriptRes)
	staticBodyNode.add_child(meshNode)
	if meshNode.has_meta("materialType"):
		staticBodyNode.set_meta("materialType", meshNode.get_meta("materialType"))

	
	
	geometryParentNode.add_child(staticBodyNode)
	return

func getBB(verts):
	var minX = INF
	var minY = INF
	var minZ = INF

	var maxX = -INF
	var maxY = -INF
	var maxZ = -INF

	for v in verts:
		if v.x < minX:
			minX = v.x
		if v.y < minY:
			minY = v.y
		if v.z < minZ:
			minZ = v.z

		if v.x > maxX:
			maxX = v.x
		if v.y > maxY:
			maxY = v.y
		if v.z > maxZ:
			maxZ = v.z


	var minDim = Vector3(minX,minY,minZ)
	var maxDim = Vector3(maxX,maxY,maxZ)
	var absDim = maxDim - minDim
	return({"dim":absDim,"min":minDim,"max":maxDim})

func projectToXYbasic(verts):
	var out = []
	var origin = getCenter(verts)
	var planeLine1 = (verts[1] - origin).normalized()
	var planeLine2 = (verts[2] - origin).normalized()



	var X = planeLine1
	var Z = planeLine1.cross(planeLine2).normalized()
	var Y = Z.cross(X).normalized()

	var t = Transform(X,Y,Z,Vector3.ZERO)

	for vert in verts:
		out.append(t.xform_inv(vert))

	return {"vertices":out,"transform":t,"origin":origin}



func saveVertsAsPolyImage(verts,namStr):
	#print(verts)
	var poly = Polygon2D.new()
	poly.scale *= 10
	poly.polygon = verts
	var packed_scene = PackedScene.new()
	packed_scene.pack(poly)
	ResourceSaver.save("res://" + namStr + ".tscn",packed_scene)

func removeADup(v):
	#print(v.size())
	if v.size() == 1:
		return
	var indexes = []
	for j in v.size():
			for k in range(j+1,v.size()):

				var a = v[j]
				var b = v[k]
				var diff = a-b

				if(abs(diff.x) < 0.0001 and abs(diff.y) < 0.0001 and abs(diff.z) < 0.0001):
					v.remove(k)
					return true

	return false

func findCommonverts(v1,v2):
	var commonIndexes = []
	var count = 0
	#if v1.size() <v2.size():
	#	var temp = v1
	##	v1 = v2
	#	v2 = temp

	for i in range(0,v1.size()):
		for j in range(0,v2.size()):
			var a = v1[i]
			var b = v2[j]
			var diff = a-b

			if(abs(diff.x) < 0.0001 and abs(diff.y) < 0.0001 and abs(diff.z) < 0.0001):
				count += 1
				commonIndexes.append([i,j])#we get all common tuples

	if count < 2:#its only valid if two vertices are in common. But we only return the CW one
		return null


	var firstCommonbefore = (commonIndexes[0][0]-1)%v1.size()

	var fistCommonA = commonIndexes[0][0]
	var fistCommonB = commonIndexes[0][1]
	var firstCommonafter = (commonIndexes[0][1]+1)%v2.size()

	var firstLineA = (v1[firstCommonbefore]-v1[fistCommonA]).normalized()
	var firstLineB = (v2[fistCommonB]-v2[firstCommonafter]).normalized()
	fistCommonB

	var secondCommonbefore = (commonIndexes[1][0]-1)%v1.size()

	var secondCommonA = commonIndexes[1][0]
	var secondCommonB = commonIndexes[1][1]
	var secondCommonafter = ((commonIndexes[1][1])+1)%v2.size()

	var secondLineA = (v1[secondCommonbefore]-v1[secondCommonA]).normalized()
	var secondLineB = (v2[secondCommonB]-v2[secondCommonafter]).normalized()


	
	if(firstLineA.dot(firstLineB)==1 or firstLineA.dot(firstLineB)==0):
		return commonIndexes[0]
	elif(secondLineA.dot(secondLineB)==1):
		return commonIndexes[1]
	else:
		return null


	return commonIndexes


func coplanarCombine(a,b):
	#return null
	for textureName in a["fans"].keys():
		if b["fans"].has(textureName):
			for f1 in a["fans"][textureName]:
				for f2 in b["fans"][textureName]:
					if f1["normal"] == f2["normal"]:
						var v1 = f1["verts"]
						var v2 = f2["verts"]
				
						print(v1)
						print(v2)
						var combined = combineVerts(v1,v2)
						if combined != null:
							f1["verts"] = combined
							b["fans"][textureName].erase(f2)
							#breakpoint
						print(combined)
				
				
	#var norm1 = f1#planes[f1["planeIndex"]]["normal"]
	#var norm2 = planes[f2["planeIndex"]]["normal"]
	#if norm1 != norm2:
		#print("normal not equal:",norm1,",",norm2)
	#	return null

	#var combined = combineVerts(f1["verts"],f2["verts"])
	#if combined == null:
	#	print()

	return true#combined


func combineVerts(v1,v2,debug=false):


	v1 = removeColinear(v1)
	v2 = removeColinear(v2)
	if v1.size()!=4:
		return null
		
	if v2.size()!=4:
		return null
	var comms = findCommonverts(v1,v2)
	if comms == null:
		return null
	if comms == []:
		return null
	var finalComb = []


	var merged = false
	for a in range(0,v1.size()):

		if a == comms[0] and merged == false:
			var bStart = comms[1]

			for b in range(0,v2.size()-1):
				finalComb.append(v2[(bStart+b)%v2.size()])
				merged = true


		else: finalComb.append(v1[a])

	return finalComb


func getTopLeftVert(verts):
	var TL = Vector3(INF,-INF,INF)
	for v in verts:
		if v.x < TL.x: TL.x = v.x
		if v.y > TL.y: TL.y = v.y
		if v.z < TL.z: TL.z = v.z
	return Vector3(TL.x,TL.y,TL.z)

func getBottomRightVert(verts):
	var TL = Vector3(-INF,INF,-INF)
	for v in verts:
		if v.x > TL.x: TL.x = v.x
		if v.y < TL.y: TL.y = v.y
		if v.z > TL.z: TL.z = v.z
	return Vector3(TL.x,TL.y,TL.z)


	var out = []

	for v in verts:
		out.append(transform.xform_inv(v))

	var tl = getTopLeftVert(out)
	for v in out.size():
		out[v] -= tl

	return out


func uvProjection(vert,normal):
	var e1 = normal.cross(Vector3(0,1,0)).normalized()
	if e1 == Vector3.ZERO: #is parallel to x axis
		e1 = normal.cross(Vector3(0,0,1)).normalized()

	var e2 = normal.cross(e1).normalized()
	var u = vert.dot(e1)
	var v = vert.dot(e2)
	return Vector2(u,v)



func removeColinear(verts):
	var out = []
	
	for v in verts.size():
		var a = verts[(v-1)%verts.size()]
		var b = verts[(v)]
		var c = verts[(v+1)%verts.size()]
		if (b-a).normalized() == (c-b).normalized():
			continue

		out.append(verts[v])
	return out



func generateEdgeTrackerFaces():
	var retMeshes = []
	var hotFaces = get_parent().hotFaces
	var firstskipped = false

	var mergeTextureFactor = get_parent()
	renderables = get_parent().renderables
	renderableEdges = get_parent().renderableEdges
	var faceIdx = -1 
	for face in renderables:
		faceIdx += 1
		if face.size()==0:
			continue
		
		
		var mergeHappened = true
		while(mergeHappened):
			mergeHappened = false
			for edge in renderableEdges[faceIdx]:
				if edgeToFaceIndexMap.has(edge):
					
					if edgeToFaceIndexMap[edge].size() < 2:
						continue
					var test = edgeToFaceIndexMap[edge]
					
					if test.size()<2:
						continue

					var otherFaceIdx

					if test[0] == faceIdx: otherFaceIdx = test[1]
					elif test[1] == faceIdx: otherFaceIdx = test[0]
					else:
						continue
					
					if faceIdx == otherFaceIdx: continue
					var otherFace = renderables[otherFaceIdx]
					
					var cont = false
					if face.keys().size() == get_parent().texturesPerMesh:
						var otherFaceTextures = otherFace.keys()
						for t in otherFaceTextures:
								if !face.has(t):
									cont = true
									
					if cont == true: continue
					
					for texture in face:
						if(hotFaces.has(otherFaceIdx) or renderModeFaces.has(otherFaceIdx)): 
							continue
						
						
						var combined =null
						var flag = mergeFaceFunc(faceIdx,otherFaceIdx)

						if flag == false:
							continue

						mergeHappened = true
						
						var otherFacesEdges = renderableEdges[otherFaceIdx].duplicate()
						renderableEdges[otherFaceIdx].clear()
						renderableEdges[faceIdx] += otherFacesEdges
							
						for e in otherFacesEdges:
							if !edgeToFaceIndexMap.has(e):
								continue
							if edgeToFaceIndexMap[e].size()<1:
								continue

							if edgeToFaceIndexMap[e][0] == otherFaceIdx:
								edgeToFaceIndexMap[e][0] = faceIdx

							if edgeToFaceIndexMap[e].size()<2:
								continue

							if edgeToFaceIndexMap[e][1] == otherFaceIdx:
								edgeToFaceIndexMap[e][1] = faceIdx

						edgeToFaceIndexMap.erase(edge)#edge dosen't exist anymore
					
	return


func mergeFaceFunc(f1Index,f2Index,hotFaces = false):
		if renderables.size() < f2Index:
			return false
		
		var f1 = renderables[f1Index]
		var f2 = renderables[f2Index]
		var mergeCount = 0
		
		if renderableEdges[f1Index].empty() or renderableEdges[f2Index].empty():
			return false
			
		var newTextureCount = 0
		if !hotFaces:
			var seenDict = {}
			for textureName in f2:
				if !f1.has(textureName) and !seenDict.has(textureName):
					seenDict[textureName] = true
					newTextureCount +=1
		else:
			newTextureCount = -INF
		
		
		if (f1.size() + newTextureCount) > get_parent().texturesPerMesh:
			return false
		
		
		for textureName in f2:
			var normals1 = getFansNormals(f1)#
			var normals2 = getFansNormals(f2)
			if normals1.size() > 3 and !hotFaces: continue
			if normals2.size() > 3 and !hotFaces: continue
			
			var norm2 = f2[textureName][0]["normal"]
			if f1.has(textureName):
				var norm1 = f1[textureName][0]["normal"]
				if norm2 == norm1 or hotFaces:#this stops the lightmap unwrap function from asserting false but not sure why
					#print(norm1,",",norm2)
					f1[textureName] += f2[textureName]
					f2.erase(textureName)
					mergeCount+=1
				else:
					if mergeCount > 0:
						breakpoint
					return false
			else:
					#if f1[f1.keys()[0]][0]["normal"] == norm2 or hotFaces:
					#if f1[f1.keys()[0]][0]["normal"] == norm2 or hotFaces:
					if normals1 == normals2 or hotFaces:
						f1[textureName] = f2[textureName]
						f2.erase(textureName)
						mergeCount +=1
					#if norm2 == norm1:
					#	print(angle)
					#	f1[textureName] = f2[textureName]
					#	f2.erase(textureName)
					#	mergeCount+=1
					else:
						if mergeCount > 0:
							breakpoint
						return false
						
		
		
		#for textureName in f2:
		#	if f1.has(textureName):
		#		f1[textureName] += f2[textureName]
		#		f2.erase(textureName)
		#	else:
		#		f1[textureName] = f2[textureName]
		#		f2.erase(textureName)
		if mergeCount == 0:
			return false
		return true



func mergeBrushModelFaces3():
	var first = true
	var faces 
	#var test0 = get_parent().modelRenderModes
	for model in brushModels:
		if first:
			first = false
			continue
		
		var modelFaceIdxs = model["faceArr"].duplicate()
		if modelFaceIdxs.size() < 1:
			return
		
		var face1Idx = modelFaceIdxs.pop_front()
		var face1 = renderables[face1Idx]
		
		for faceBIdx in modelFaceIdxs:
			var faceB = renderables[faceBIdx]
			
			if renderModeFaces.has(faceBIdx):
				print("model contains render surface")
				continue

			var flag = mergeFaceFunc(face1Idx,faceBIdx,true)
			if flag == false:
				continue
			renderModeFaces.erase(faceBIdx)
			
					


func loadTGAasImage(path):
	var file = File.new()
	file.open(path,File.READ)
	var buffer = file.get_buffer(file.get_len())

	var image = Image.new()
	image.load_tga_from_buffer(buffer)

	file.close()
	return image

func rotImage(image:Image,dir):
	var w = image.get_width()
	var h = image.get_height()



	var size = image.get_size().x * image.get_size().y
	var rotImage = image.duplicate()

	image.lock()
	rotImage.lock()

	for x in image.get_width():
		for y in image.get_height():
			var pix = image.get_pixel(x,y)
			if dir == "top":
				rotImage.set_pixel(y,w-1-x,pix)
			if dir == "bottom":
				rotImage.set_pixel(h-1-y,x,pix)

	image.unlock()
	rotImage.unlock()
	return rotImage
	#breakpoint

func textureLights():
	return
	var meshNodes = get_parent().faceMeshNodes
	
	var textureLightPar = Spatial.new()
	textureLightPar.name = "Texture Lights"
	get_parent().add_child(textureLightPar)
	var oneshotDict = {}
	for f in meshNodes.values():
		if f == null:
			continue
			
		if f.has_meta("textureName"):
			var textureName = f.get_meta("textureName")
			if rads.has(textureName):
				
				var color = rads[textureName]
				var light = SpotLight.new()
				var normal = f.get_meta("normal")
				
				#light.omni_range = 125
				light.name = textureName
				light.light_color = color
				light.light_energy = 1.7
				textureLightPar.add_child(light)
				light.spot_range = 47
				light.spot_attenuation = 1.72
				light.spot_angle = 42
				light.spot_angle_attenuation = 1.2
				light.light_indirect_energy = 3
				light.translation += f.global_transform.origin

		
				light.translation -= normal*get_parent().scaleFactor*5
				light.set_meta("norm",normal)
				light.set_meta("angle",atan2(normal.z,normal.y))
				
			
				var ang = acos(normal.dot(Vector3(0,0,1)))
				var rotAxis = normal.cross(Vector3(0,0,1))
				light.rotate(rotAxis,ang)
				#light.rotate_x(atan2(normal.z,normal.y))#rad2deg(90))

				#light.rotation_degrees.x += 90
				#light.shadow_enabled = true
				var indirectFake : OmniLight = OmniLight.new()
				textureLightPar.add_child(indirectFake)
				indirectFake.translation += f.global_transform.origin +  normal*get_parent().scaleFactor*10
				indirectFake.omni_range = 10
				if !oneshotDict.has(textureName):
					
					oneshotDict[textureName] = 1


func getFansNormals(fans):
	var normals = []
	for texture in fans.keys():
		for face in fans[texture]:
			var normal = face["normal"]
			if !normals.has(normal):
				normals.append(normal)

	return normals
	

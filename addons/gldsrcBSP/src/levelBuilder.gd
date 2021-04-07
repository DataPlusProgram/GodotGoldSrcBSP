tool
extends Spatial

var faces
var edges
var surfEdges
var vertices
var planes
var textures
var textureInfos
var brushModels
var geometryParentNode = null
var edgeToFaceIndexMap
#var workingFaceMeshNodes = {}
var linkedFacesDict = {}
var theFaceIndex = 0
var hotFaces
var renderModeFaces
var skyMat = null
var cubeMapShader = preload("res://addons/gldsrcBSP/cubemap.shader")
var skyCubemap = null
var kinematicBodies = true

var rads = {
	"+0~GENERIC65": Color(1,1,1),
	"+0~GENERIC85":Color(1,1,1),
	"~+0LAB1_W6D" : Color(1,1,1),
	"~+0LAB1_W6" : Color(1,1,1),
	"~+0LAB1_W7":Color(1,1,1),
	"~LIGHT2A" : Color(1,1,1),
	"~LIGHT3B" : Color(1,1,1),
	"~LIGHT3C" : Color(1,1,1),
	"~LIGHT5A" : Color(1,1,1),
	"~LIGHT5F" : Color(1,1,1),
	"+0~FIFTS_LGHT01": Color(1,1,1),
	"+0~FIFTIES_LGT2": Color(1,1,1),
	#"+0~FIFTS_LGHT4": Color(1,1,1),
	"~EMERGLIGHT":Color(1,1,1),
	"+0~LAB_CRT8":Color(1,1,1),

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
	faces = get_parent().faces
	surfEdges = get_parent().surfaces
	edges = get_parent().edges
	planes = get_parent().planes
	textureInfos = get_parent().textureInfo
	textures = get_parent().textures
	brushModels = get_parent().brushModels
	hotFaces = get_parent().hotFaces
	edgeToFaceIndexMap = get_parent().edgeToFaceIndexMap

	textureLights2()
	if get_parent().optimize == true:
		var a = OS.get_system_time_secs()
		generateEdgeTrackerFaces()
		mergeBrushModelFaces2()

	for face in faces:
		var faceIndex = faces.find(face)

		var edge
		var plane = planes[face["planeIndex"]]
		var texInfo = textureInfos[face["textureInfo"]]
		var textureI = textures[texInfo["textureIndex"]]
		var textureName = textureI["name"]
		faces[faceIndex]["textureName"] = textureName


		var texture = null

		if textureName == "AAATRIGGER":
			get_parent().faceMeshNodes[faceIndex] = null
			continue



		var norm = plane["normal"]
		if face["planeSide"] == 1: norm = -norm
		face["normal"] = norm


		var meshNode = null

		if !face.has("fans"):
			if face["verts"] != []:
				meshNode = createMeshFromFan(face["verts"],textureName,norm,faceIndex,texInfo)
				meshNode.use_in_baked_light = true
				get_parent().faceMeshNodes[faceIndex] =meshNode
				geometryParentNode.add_child(meshNode)
		else:
			if face["fans"].size()>0:
				#if get_parent().simpleCombine:
				#	fanMerge(face["fans"])
				var fanMesh  = createMeshFromFanArr(face["fans"],textureName,norm,faceIndex,texInfo)
				if fanMesh != null:
					fanMesh.set_meta("fans",face["fans"])
					fanMesh.use_in_baked_light = true
					get_parent().faceMeshNodes[faceIndex] =fanMesh
					geometryParentNode.add_child(fanMesh)


	#Global.createWindowDict(edgeToFaceIndexMap,200,500,"edgeToFaceIndexMap")
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
		for fan in fans[textureName]:
			center += getCenter(fan["verts"])
			count +=1


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


func createMesh(vertices,textureName,normal,faceIndex,texInfo):
	var texture
	var center = getCenter(vertices)
	var fiddleScale = 1
	var surf = SurfaceTool.new()
	var mesh = Mesh.new()
	if hotFaces.has(faceIndex):
		breakpoint

	var mat

	if !get_parent().disableTextures:
		texture =get_parent().fetchTexture(textureName)
		if textureName!="SKY":
			mat = createMat(texture,textureName)
		else:
			breakpoint


	get_parent().faceIndexToMaterialMap[faceIndex] = mat



	surf.begin(Mesh.PRIMITIVE_TRIANGLE_FAN)
	if !get_parent().disableTextures:
		surf.set_material(mat)


	for v in vertices.size():
		surf.add_normal(normal)
		surf.add_vertex((vertices[v]-center)*fiddleScale)
	surf.index()
	surf.commit(mesh)

	var meshNode = MeshInstance.new()
	meshNode.name = "face_mesh_" + String(faceIndex)
	#meshNode.translation = center
	mesh.lightmap_unwrap(Transform.IDENTITY,1)
	meshNode.mesh = mesh
	get_parent().faceMeshNodes[faceIndex] = meshNode
	meshNode.set_meta("vertices",surf.commit_to_arrays())
	var matType = getMatType(textureName)
	meshNode.set_meta("materialType",matType)
	meshNode.set_meta("textureName",textureName)
	meshNode.set_meta("normal",normal)

	return meshNode

func createMeshFromFan(vertices,textureName,normal,faceIndex,texInfo,localUV = true):

	var texture
	var center = getCenter(vertices)
	var fiddleScale = 1
	var surf = SurfaceTool.new()
	var mesh = Mesh.new()

	#var centerVerts = vertices.duplicate()

	var mat

	if !get_parent().disableTextures:
		texture =get_parent().fetchTexture(textureName)

		if textureName!="SKY":
			mat = createMat(texture,textureName)
		else:
			mat = createMatSky()


	get_parent().faceIndexToMaterialMap[faceIndex] = mat


	surf.begin(Mesh.PRIMITIVE_TRIANGLES)
	if !get_parent().disableTextures:
		surf.set_material(mat)


	var triVerts = []
	var triNormals = []
	var triUV = []
	var TL = Vector2(INF,INF)
	for v in vertices.size():


		var projVert
		projVert = texProject(vertices[v],texInfo,texture)

		vertices[v] -= center
		triNormals.append(normal)
		triVerts.append(vertices[v])


		triUV.append(projVert)
		if projVert.x < TL.x: TL.x = projVert.x
		if projVert.y < TL.y: TL.y = projVert.y


	surf.add_triangle_fan(triVerts,triUV,[],triUV,triNormals)
	#surf.add_vertex(vertices[v]*fiddleScale)
	surf.index()
	surf.commit(mesh)
	mesh.lightmap_unwrap(Transform.IDENTITY,1)
	var meshNode = MeshInstance.new()
	meshNode.name = "face_mesh_" + String(faceIndex)
	meshNode.translation = center
	meshNode.mesh = mesh

	get_parent().faceMeshNodes[faceIndex] = meshNode

	var matType = getMatType(textureName)

	meshNode.set_meta("vertices",surf.commit_to_arrays())
	meshNode.set_meta("materialType",matType)
	meshNode.set_meta("textureName",textureName)
	meshNode.set_meta("normal",normal)
	if hotFaces.has(faceIndex):
		meshNode.set_meta("hotFace",true)

	#print(surf.commit_to_arrays()[0])
	return meshNode

func getMatType(textureName):
	var lookupString  = textureName
	if lookupString.length() > 12:
		lookupString = lookupString.substr(0,12)

	lookupString = lookupString.trim_prefix("!")
	lookupString = lookupString.trim_prefix("~")
	lookupString = lookupString.trim_prefix("{")
	lookupString = lookupString.trim_prefix(" ")

	var matType = "C"
	if get_parent().textureToMaterialDict.has(lookupString):
		matType = get_parent().textureToMaterialDict[lookupString]

	return matType

func createMeshFromFanArr(fans,textureName,normal,faceIndex,texInfo):
	var center =getCenterFanArr(fans)
	var texture
	var fiddleScale = 1
	var surf = SurfaceTool.new()
	var runningMesh = ArrayMesh.new()

	var matType = getMatType(textureName)


	var mat

	if !get_parent().disableTextures:
		texture =get_parent().fetchTexture(textureName)
		if textureName!="SKY":
			mat = createMat(texture,textureName)
		else:
			mat = createMatSky()

	get_parent().faceIndexToMaterialMap[faceIndex] = mat
	surf.begin(Mesh.PRIMITIVE_TRIANGLES)


	var count = 0
	var hasVerts = false
	#print("textures in fan:",fans.keys())
	for textureName in fans:
		var localSurf = SurfaceTool.new()
		var localMesh = ArrayMesh.new()
		texture =get_parent().fetchTexture(textureName)
		if !get_parent().disableTextures:
			if textureName!="SKY":
				mat = createMat(texture,textureName,renderModeFaces)
			else:
				mat = createMatSky()
		localSurf.set_material(mat)
		localSurf.begin(Mesh.PRIMITIVE_TRIANGLES)
		#print(textureName)
		#print(mat)
		#mesh = Mesh.new()
		for fan in fans[textureName]:

			var triVerts = fan["verts"]

			if triVerts == null:
				continue

			if triVerts.size()<3:
				continue

			var triNormals = []
			var triUV = []
			var vertsLocal = []
			for i in triVerts:
				vertsLocal.append(i-center)
				triNormals.append(fan["normal"])
				#var proj = uvProjection(i,fan["normal"])
				var proj = texProject(i,fan["texinfo"],texture)
				triUV.append(proj)



			localSurf.add_triangle_fan(vertsLocal,triUV,[],triUV,triNormals)
		#localSurf.commit(localMesh)
		localSurf.commit(runningMesh)



		runningMesh.surface_set_material(count,mat)
		runningMesh.surface_set_name(count,textureName)
		count+=1




	surf.commit(runningMesh)

	var meshNode = MeshInstance.new()
	meshNode.name = "face_mesh_" + String(faceIndex)
	#meshNode.translation = center
	meshNode.mesh = runningMesh
	get_parent().faceMeshNodes[faceIndex] = meshNode
	meshNode.set_meta("vertices",surf.commit_to_arrays())
	meshNode.translation = center
	#print(surf.commit_to_arrays()[0])
	meshNode.set_meta("materialType",matType)
	meshNode.set_meta("textureName",textureName)
	meshNode.set_meta("normal",normal)
	if hotFaces.has(faceIndex):
		meshNode.set_meta("hotFace",true)
	return meshNode




func createMat(texture,textureName,render = null):


	var matCacheName = textureName# + String(texInfo["fSShift"]) + String(texInfo["fTShift"])# + String(texInfo["vS"]) + String(texInfo["vT"])

	var matDict = get_parent().fetchMaterial(matCacheName)
	#var mat = SpatialMaterial.new()
	var mat = matDict["material"]



	if matDict["isFirstInstance"]:
		if texture != null:
			var textureDim = texture.get_size()
			mat.albedo_texture = texture

			if texture.get_data().detect_alpha() != 0:
				mat.flags_transparent =true

		mat.flags_world_triplanar = true
		#mat.uv1_triplanar = true
		get_parent().saveToMaterialCache(matCacheName,mat)

	return(mat)
	#print(vertices)

func createMatSky():

	if skyMat == null:
		var path = get_parent().skyTexture
		var bmpLoader = get_parent().get_node("bmpLoader")


		#var left = bmpLoader.getImageFromBMP(path + "lf.bmp")
		#var right = bmpLoader.getImageFromBMP(path + "rt.bmp")
		#var bottom = bmpLoader.getImageFromBMP(path + "dn.bmp",true)
		#var top = bmpLoader.getImageFromBMP(path + "up.bmp",true)
		#var front = bmpLoader.getImageFromBMP(path + "ft.bmp")
		#var back =  bmpLoader.getImageFromBMP(path + "bk.bmp")

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
		meshNode.create_convex_collision()
	#if(meshNode.get_children()) == []:
	#	return
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

func createCollisionsForMesh2(meshNode):

	#if meshNode.get_meta("textureName")[0]  == "!":
	#	return

	var center = meshNode.translation

	meshNode.translation = Vector3.ZERO
	if meshNode.get_meta("textureName")[0]  != "!":#not water
		meshNode.create_trimesh_collision()
	else:
		meshNode.create_convex_collision()
	#if(meshNode.get_children()) == []:
	#	return
	meshNode.get_parent().remove_child(meshNode)
	var staticBodyNode = meshNode.get_child(0)

	if meshNode.has_meta("hotFace"):
		var shape = staticBodyNode.get_child(0)
		shape.get_parent().remove_child(shape)
		staticBodyNode.queue_free()
		staticBodyNode = KinematicBody.new()
		#staticBodyNode.add_child(shape)
		if meshNode.has_meta("fans"):
			print(meshNode.get_meta("fans"))
		#for i in meshNode.get_meta("fans"):
		#	print(i)
			
		
	
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
				commonIndexes.append([i,j])

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


	#print(firstLineA.dot(firstLineB))
	#print(secondLineA.dot(secondLineB))
	if(firstLineA.dot(firstLineB)==1 or firstLineA.dot(firstLineB)==0):
		return commonIndexes[0]
	elif(secondLineA.dot(secondLineB)==1):
		return commonIndexes[1]
	else:
		return null

#	print("----")
	return commonIndexes


func coplanarCombine(f1,f2):
	#return null

	var norm1 = planes[f1["planeIndex"]]["normal"]
	var norm2 = planes[f2["planeIndex"]]["normal"]
	if norm1 != norm2:
		#print("normal not equal:",norm1,",",norm2)
		return null

	var combined = combineVerts(f1["verts"],f2["verts"])
	#if combined == null:
	#	print()

	return combined


func combineVerts(v1,v2,debug=false):

	#if get_parent().simpleCombine == false:
	#	return null
	v1 = removeColinear(v1)
	v2 = removeColinear(v2)
	var comms = findCommonverts(v1,v2)
	if comms == null:
		return null
	if comms == []:
		return null
	var finalComb = []
	#v2.erase(comms[0][1])
	#v2.erase(comms[1][1])

	var merged = false
	for a in range(0,v1.size()):

		if a == comms[0] and merged == false:
			var bStart = comms[1]

			for b in range(0,v2.size()-1):
				finalComb.append(v2[(bStart+b)%v2.size()])
				merged = true


		else: finalComb.append(v1[a])#there is an optimization to be found here if you only include the commonovverts once and know it won't cause a bad poly
	#if debug:
		#print(comms)
		#print(v1)
		#print(v2)
		#print("final:",finalComb)
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

func projectVerts(verts):
	var origin = Vector3.ZERO
	var line1 = (verts[1] - verts[0]).normalized()

	var line2 = (getCenter(verts) - verts[0]).normalized()

	var normal = line1.cross(line2).normalized()

	var side = line1.cross(normal).normalized()

	var transform =  Transform(line1,side,normal,Vector3.ZERO)
	var out = []#normal

	for v in verts:
		out.append(transform.xform_inv(v))

	return out

func projectVerts2(verts):#aligns to top left
	var TL = getTopLeftVert(verts)
	var dim = getBB(verts)["min"]# + getBB(verts)["dim"]
	var center = getCenter(verts)

	var origin = Vector3.ZERO
	var line1 = (verts[1] - verts[0]).normalized()
	var line2 = (getCenter(verts) - verts[0]).normalized()
	var normal = line1.cross(line2).normalized()
	var side = line1.cross(normal).normalized()

	var transform =  Transform(line1,side,normal,Vector3.ZERO)




	#var transform =  Transform(line1,normal,side,Vector3.ZERO)
	#var transform =  Transform(side,line1,normal,Vector3.ZERO)
	#var transform =  Transform(side,normal,line1,Vector3.ZERO)
	#var transform =  Transform(normal,side,line1,Vector3.ZERO)
	#var transform =  Transform(normal,line1,side,Vector3.ZERO)
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



func texProject(vert,texInfo,texture):
	if texture == null:
		return Vector2.ZERO

	var vs = texInfo["vS"]
	var fShift = texInfo["fSShift"]
	var vt = texInfo["vT"]
	var tShift = texInfo["fTShift"]


	var u = vert.dot(vs) #+ fShift# / texture.get_width())
	var v = vert.dot(vt) #+ tShift#/ texture.get_height())

	u /=  texture.get_width() * get_parent().scaleFactor
	v /=  texture.get_height() * get_parent().scaleFactor

	u += fShift / texture.get_width()
	v += tShift / texture.get_height()
	return Vector2(u,v)

func projectVerts3(verts):
	var TL = getTopLeftVert(verts)
	var line1 = (verts[1] - verts[0]).normalized()
	var line2 = (getCenter(verts) - verts[0]).normalized()
	var normal = line1.cross(line2).normalized()
	var side = line1.cross(normal).normalized()


	var transform =  Transform(line1,side,normal,Vector3.ZERO)
	var out= []
	for v in verts:
		out.append(transform.xform_inv(v))

	return {"vertices":out,"transform":transform}

func removeVerts(verts):
	for v in verts.size():
		var a = verts[(v+0)%verts.size()]
		var b = verts[(v+1)%verts.size()]
		var c = verts[(v+2)%verts.size()]
		var s1 = (a-b).normalized()
		var s2 = (c-a).normalized()
		if s1 == s2:
			breakpoint


func removeColinear(verts):
	var out = []

	for v in verts.size():
		var a = verts[(v-1)%verts.size()]
		var b = verts[(v)]
		var c = verts[(v+1)%verts.size()]
		if (b-a).normalized() == (c-b).normalized():
			continue

		out.append(verts[v])
		#out.append(Vector3())
	return out



func generateEdgeTrackerFaces():
	var retMeshes = []
	var hotFaces = get_parent().hotFaces
	var firstskipped = false


	var facesToMerge = get_parent().faces
	var itt = 0

	for face in faces:
		var mergeHappened = true

		var faceIdx = faces.find(face)
		#print("-->",faceIdx)
		#var deleteEdges = []
		#print("pre edges f1:",face["actualEdges"])
		while(mergeHappened):
			mergeHappened = false

			for edge in face["actualEdges"]:

				var edgeIndex = face["actualEdges"]

				if edgeToFaceIndexMap.has(edge):
					var test = edgeToFaceIndexMap[edge]
					#print("checking edge ", edge, " with faces ", test)
					if test.size()<2:
						continue

					var otherFaceIdx


					if test[0] == faceIdx: otherFaceIdx = test[1]
					elif test[1] == faceIdx: otherFaceIdx = test[0]
					else:
					#	print("cur face not in edge")
						continue

					if hotFaces.has(otherFaceIdx) or renderModeFaces.has(otherFaceIdx):
						continue
					#if get_parent().renderModeFaces.has(otherFaceIdx):
					#	breakpoint

					var textureName = face["textureName"]#textureI["name"]
					var textureName2 = faces[otherFaceIdx]["textureName"]

					var f1 =  face
					var f2 = faces[otherFaceIdx]
					var ti1 =  textureInfos[f1["textureInfo"]]
					var ti2 = textureInfos[f2["textureInfo"]]
					#if ti1 != ti2:
					#	continue

					if textureName2 != textureName:
						continue



					if faceIdx == otherFaceIdx:
					#	print("same faces")
						continue

					var a = OS.get_system_time_msecs()

					var combined =null
					if get_parent().simpleCombine:
						combined = coplanarCombine(faces[faceIdx],faces[otherFaceIdx])
						if combined == null:
							print("failed combine on:",faceIdx,",",otherFaceIdx)

					if combined != null:

						print("coplanar combine worked on:",faceIdx,",",otherFaceIdx)
					#	print(faceIdx,",",otherFaceIdx)
					#	print(faces[faceIdx]["verts"])
					#	print(faces[otherFaceIdx]["verts"])
					#	print(combined)
					#	print("-------")
						faces[faceIdx]["verts"] = combined
						faces[otherFaceIdx]["verts"] = []

					else:
						var flag = mergeFaceFunc(faceIdx,otherFaceIdx)

						if flag == false:
							continue

					mergeHappened = true
					#print("merged: ",faceIdx,",",otherFaceIdx," ",faces[faceIdx]["origFaces"])
					#print(faces[otherFaceIdx]["actualEdges"])
					var otherFacesEdges = faces[otherFaceIdx]["actualEdges"].duplicate()

					faces[otherFaceIdx]["actualEdges"] = [] #face edges set to zero so when the loop gets to it nothing is checked
					faces[faceIdx]["actualEdges"] += otherFacesEdges



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


			#print("post edges:",face["actualEdges"])
	return



func mergeFaceFunc(f1Index,f2Index,itt = 0):

		if faces.size() < f2Index:
			return false
		var f1 = faces[f1Index]
		var f2 = faces[f2Index]



		if !f1.has("verts") and !f1.has("fans"): return null
		if !f2.has("verts") and !f2.has("fans"): return null

		#print(faces[f2Index]["actualEdges"])
		if faces[f1Index]["actualEdges"].empty() or faces[f2Index]["actualEdges"].empty():
			return false


		var norm1 = planes[f1["planeIndex"]]["normal"]
		var norm2 = planes[f2["planeIndex"]]["normal"]

		if f1["planeSide"] == 1: norm1 = -norm1
		if f2["planeSide"] == 1: norm2 = -norm2


		var m1 = faces[f1Index]
		var m2 = faces[f2Index]

		if m1 == null or m2 == null:
			return false
		var textureName = f1["textureName"]

		if !f1.has("fans"):
			if f1["verts"] != []:
				f1["fans"] = {}
				var texInfo = f1["textureInfo"]
				f1["fans"][textureName] = [{"verts":f1["verts"],"normal":norm1,"texinfo":textureInfos[texInfo]}]#don't want [[empty]]
			else:
				f1["fans"][textureName] = {}


		var f2textureName = f2["textureName"]
		if f2.has("fans"):
			f1["fans"][f2textureName] += f2["fans"]
			f1["origFaces"] += f2["origFaces"]
			f2.erase("fans")

		if f2["verts"] != []:# and f1.has("fans"):
			var texInfo = f2["textureInfo"]
			if !f1["fans"].has(f2textureName):
				f1["fans"][f2textureName] = []
			f1["fans"][f2textureName].append({"verts":f2["verts"],"normal":norm2,"texinfo":textureInfos[texInfo]})
			f1["origFaces"].append(f2Index)

		faces[f1Index]["verts"] = []
		faces[f2Index]["verts"] = []

		return true


func mergeBrushModelFaces2():
	var first = true
	var test0 = get_parent().modelRenderModes
	var idx = -1
	for model in brushModels:

		idx+=1
		if first:
			first = false
			continue
		#if get_parent().modelRenderModes.has(String(idx)):
		#	continue
		#	breakpoint
		var modelFaceIdxs = model["faceArr"]
		#var faceIdxs = faces[modelFaceIdxs]
		var mergeHappened = true
		for faceIdx in modelFaceIdxs:
			var face = faces[faceIdx]
			if renderModeFaces.has(faceIdx):
				continue
				#breakpoint

			#var faceIdx = faces.find(face)
			#print("-->",faceIdx)
			#var deleteEdges = []
			#print("pre edges f1:",face["actualEdges"])
			while(mergeHappened):
				mergeHappened = false

				for edge in face["actualEdges"]:

					var edgeIndex = face["actualEdges"]

					if edgeToFaceIndexMap.has(edge):
						var test = edgeToFaceIndexMap[edge]
						#print("checking edge ", edge, " with faces ", test)
						if test.size()<2:
							continue

						var otherFaceIdx


						if test[0] == faceIdx: otherFaceIdx = test[1]
						elif test[1] == faceIdx: otherFaceIdx = test[0]
						else:
							#print("cur face not in edge")
							continue

						if !hotFaces.has(otherFaceIdx) or renderModeFaces.has(otherFaceIdx):
							print("not in hot face")
							continue
						#if get_parent().renderModeFaces.has(otherFaceIdx):
						#	breakpoint

						var textureName = face["textureName"]#textureI["name"]
						var textureName2 = faces[otherFaceIdx]["textureName"]

						var f1 =  face
						var f2 = faces[otherFaceIdx]
						var ti1 =  textureInfos[f1["textureInfo"]]
						var ti2 = textureInfos[f2["textureInfo"]]
						#if ti1 != ti2:
						#	continue

						#if textureName2 != textureName:
						#	print("textures not the same")
						#	continue

						if faceIdx == otherFaceIdx:
							#print("same faces")
							continue

						var a = OS.get_system_time_msecs()


						var combined =null
						if combined != null:
							#print("combine:",faceIdx,",",otherFaceIdx)
						#	print(faceIdx,",",otherFaceIdx)
						#	print(faces[faceIdx]["verts"])
						#	print(faces[otherFaceIdx]["verts"])
						#	print(combined)
						#	print("-------")
							faces[faceIdx]["verts"] = combined
							faces[otherFaceIdx]["verts"] = []

						else:
							var flag = mergeFaceFunc(faceIdx,otherFaceIdx)

							if flag == false:
								#print("merge face func failed")
								continue

						mergeHappened = true
						#print("merged: ",faceIdx,",",otherFaceIdx," ",faces[faceIdx]["origFaces"])
						#print(faces[otherFaceIdx]["actualEdges"])
						var otherFacesEdges = faces[otherFaceIdx]["actualEdges"].duplicate()

						faces[otherFaceIdx]["actualEdges"] = [] #face edges set to zero so when the loop gets to it nothing is checked
						faces[faceIdx]["actualEdges"] += otherFacesEdges
						modelFaceIdxs.erase(otherFaceIdx)


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


				#print("post edges:",face["actualEdges"])



func getTexturesOfFaceArr(arr):
	var textureArr = []
	for faceIdx in arr:
		var textureName = faces[faceIdx]["textureName"]
		if !textureArr.has(textureName):
			textureArr.append(textureName)

	return textureArr

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
	var meshNodes = get_parent().faceMeshNodes
	for f in meshNodes.values():
		if f == null:
			continue
		if f.has_meta("textureName"):
			var textureName = f.get_meta("textureName")
			if rads.has(textureName):
				var color = rads[textureName]
				var light = OmniLight.new()
				var normal = f.get_meta("normal")
				print(normal)
				light.omni_range = 10
				light.name = textureName
				#light.translation += normal
				get_parent().get_node("Lights").add_child(light)


func textureLights2():
	var createdPlanes = []
	for face in faces:
		var center = getCenter(face["verts"])
		var plane = planes[face["planeIndex"]]
		var norm = plane["normal"]
		var index = face["planeIndex"]
		if createdPlanes.has(face["textureInfo"]):
			continue
		var textureName = face["textureName"]
		norm.y = -norm.y


		if rads.has(textureName):
			var color = rads[textureName]
			var light = OmniLight.new()
			light.omni_range = 20
			light.translation = center+norm*get_parent().scaleFactor*10
			get_parent().add_child(light)

		createdPlanes.append(index)
			#LineDraw.drawSphere(center+norm*get_parent().scaleFactor*10)
		#breakpoint

func CC(f1,f2):
	for face in faces:
		var norm1 = planes[f1["planeIndex"]]["normal"]
		var norm2 = planes[f2["planeIndex"]]["normal"]
		if norm1 != norm2:
		#print("normal not equal:",norm1,",",norm2)
			return null

		var combined = combineVerts(f1["verts"],f2["verts"])


	breakpoint

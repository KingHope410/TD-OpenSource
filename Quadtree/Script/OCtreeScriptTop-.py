# me - this DAT
# scriptOp - the OP which is cooking
import numpy as np

# press 'Setup Parameters' in the OP to call this function to re-create the parameters.


class AABBCC:
	def __init__(self,x,y,z,width,height,depth):
		self.x = x
		self.y = y
		self.z = z
		self.w = width
		self.h = height
		self.d = depth
		
	
	def contain(self,point):
		x = point[0]
		y = point[1]
		z = point[2]
		return (x >= self.x - self.w/2. and
		x <= self.x + self.w/2. and
		y >= self.y - self.h/2. and 
		y <= self.y + self.h/2. and
		z >= self.z - self.d/2. and
		z <= self.z + self.d/2)
		
		

class Octree:
	def __init__(self,boundary,n):
		self.boundary = boundary
		self.capacity = n
		self.points = []
		self.divide = False

	def subdivide(self):
		x = self.boundary.x
		y = self.boundary.y
		z = self.boundary.z
		w = self.boundary.w
		h = self.boundary.h
		d = self.boundary.d

		wnf = AABBCC(x-w/4, y+h/4, z+d/4, w/2, h/2, d/2)
		wnb = AABBCC(x-w/4, y+h/4, z-d/4, w/2, h/2, d/2)


		wsf = AABBCC(x-w/4, y-h/4,z+d/4, w/2, h/2, d/2)
		wsb = AABBCC(x-w/4, y-h/4,z-d/4, w/2, h/2, d/2)

		enf = AABBCC(x+w/4, y+h/4, z+d/4, w/2, h/2, d/2)
		enb = AABBCC(x+w/4, y+h/4, z-d/4, w/2, h/2, d/2)


		esf = AABBCC(x+w/4, y-h/4, z+d/4, w/2, h/2, d/2)
		esb = AABBCC(x+w/4, y-h/4, z-d/4, w/2, h/2, d/2)

		self.WNF = Octree(wnf,self.capacity)
		self.WNB = Octree(wnb,self.capacity)

		self.WSF = Octree(wsf,self.capacity)
		self.WSB = Octree(wsb,self.capacity)
		
		self.ENF = Octree(enf,self.capacity)
		self.ENB = Octree(enb,self.capacity)

		self.ESF = Octree(esf,self.capacity)
		self.ESB = Octree(esb,self.capacity)


		self.divide = True
		
	
	def insert(self,point):
		if self.boundary.contain(point) == False:
			return

		if len(self.points) < self.capacity:
			self.points.append(point)
		else:
			if self.divide == False:
				self.subdivide()
			self.WNF.insert(point)
			self.WNB.insert(point)
			self.WSF.insert(point)
			self.WSB.insert(point)
			self.ENF.insert(point)
			self.ENB.insert(point)
			self.ESF.insert(point)
			self.ENB.insert(point)

	
	def export(self,node):
		node.extend(self.points)
		if self.divide :
			self.WN.export(node)
			self.WS.export(node)
			self.EN.export(node)
			self.ES.export(node)
		return node

	def show(self,node):
		aabb = [self.boundary.x, self.boundary.y, self.boundary.z,
		self.boundary.w, self.boundary.h, self.boundary.d]
		node.extend(aabb)
		if self.divide:
			self.WNF.show(node)
			self.WNB.show(node)
			self.WSF.show(node)
			self.WSB.show(node)
			self.ENF.show(node)
			self.ENB.show(node)
			self.ESF.show(node)
			self.ENB.show(node)
		return node

	

def onCook(scriptOp):
	points = scriptOp.inputs[0].numpyArray()
	boundary = AABBCC(0.,0.,0., 1.,1.,1.) 
	qTree = Octree(boundary, 10)
	#print(points.shape)
	for i in range(len(points)):
		for j in range(len(points)):
			#print(points[i][j].shape)
			qTree.insert(points[i][j])
	
	node = []
	l = qTree.show(node)
	result = np.array(l)
	arr = result.reshape(int(len(l)/6),6)
	# print(result)
	# print(arr)
	scriptOp.store('boundary', arr) 
	# scriptOp.copyNumpyArray(points)
	return

def onSetupParameters(scriptOp):
	"""Auto-generated by Component Editor"""
	# manual changes to anything other than parJSON will be	# destroyed by Comp Editor unless doc string above is	# changed

	TDJSON = op.TDModules.mod.TDJSON
	parJSON = """
	{}
	"""
	parData = TDJSON.textToJSON(parJSON)
	TDJSON.addParametersFromJSONOp(scriptOp, parData, destroyOthers=True)
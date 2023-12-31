# me - this DAT
# scriptOp - the OP which is cooking
import numpy as np

# press 'Setup Parameters' in the OP to call this function to re-create the parameters.


class AABB:
	def __init__(self,x,y,width,height):
		self.x = x
		self.y = y
		self.w = width
		self.h = height
	
	def contain(self,point):
		x = point[0]
		y = point[1]
		return (x >= self.x - self.w/2. and
		x <= self.x + self.w/2. and
		y >= self.y - self.h/2. and 
		y <= self.y + self.h/2.)
		
		

class Quadtree:
	def __init__(self,boundary,n):
		self.boundary = boundary
		self.capacity = n
		self.points = []
		self.divide = False

	def subdivide(self):
		x = self.boundary.x
		y = self.boundary.y
		w = self.boundary.w
		h = self.boundary.h

		wn = AABB(x-w/4, y+h/4, w/2, h/2)
		ws = AABB(x-w/4, y-h/4, w/2, h/2)
		en = AABB(x+w/4, y+h/4, w/2, h/2)
		es = AABB(x+w/4, y-h/4, w/2, h/2)


		self.WN = Quadtree(wn,self.capacity)
		self.WS = Quadtree(ws,self.capacity)
		self.EN = Quadtree(en,self.capacity)
		self.ES = Quadtree(es,self.capacity)

		self.divide = True
		
	
	def insert(self,point):
		if self.boundary.contain(point) == False:
			return

		if len(self.points) < self.capacity:
			self.points.append(point)
		else:
			if self.divide == False:
				self.subdivide()
			self.WN.insert(point)
			self.WS.insert(point)
			self.EN.insert(point)
			self.ES.insert(point)
	
	def export(self,node):
		node.extend(self.points)
		if self.divide :
			self.WN.export(node)
			self.WS.export(node)
			self.EN.export(node)
			self.ES.export(node)
		return node

	def show(self,node):
		if self.divide == False:
			aabb = [self.boundary.x, self.boundary.y,
			self.boundary.w, self.boundary.h]
			node.extend(aabb)
		else :
			self.WN.show(node)
			self.WS.show(node)
			self.EN.show(node)
			self.ES.show(node)
		return node

	

def onCook(scriptOp):
	points = scriptOp.inputs[0].numpyArray()
	boundary = AABB(0.,0.,1.,1.) 
	qTree = Quadtree(boundary, 5)
	#print(points.shape)
	for i in range(len(points)):
		for j in range(len(points)):
			#print(points[i][j].shape)
			qTree.insert(points[i][j])
	
	node = []
	l = qTree.show(node)
	result = np.array(l)
	arr = result.reshape(int(len(l)/4),4)
	#print(result)
	# print(arr)
	scriptOp.store('boundary', arr) 
	#scriptOp.copyNumpyArray(points)
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
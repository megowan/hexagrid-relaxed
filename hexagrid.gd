class_name Hexagrid
extends Node

const MAX_NEIGHBORS: int = 6
const SIDE_LENGTH: float = 0.5 * tan(PI * 0.166666 * 2.0)

class GridPoint:
	var position: Vector2
	var side: bool
	var neighbors: Array[int]
	var quads: Array[int]
	func _init(p: Vector2, s: bool):
		position = p
		side = s
		neighbors = []
		quads = []

class GridTriangle:
	var a: int
	var b: int
	var c: int
	var valid: bool
	func _init(pa: int, pb: int, pc: int, pv: bool):
		a = pa
		b = pb
		c = pc
		valid = pv

class GridQuad:
	var a: int
	var b: int
	var c: int
	var d: int
	var center: int
	var neighbors: Array[int]
	func _init(pa: int, pb: int, pc: int, pd: int):
		a = pa
		b = pb
		c = pc
		d = pd
		center = -1
		neighbors = []

var side_size: int = 0
var base_quad_count: int = 0
var search_iteration_count: int = 0

var points: Array[GridPoint]
var triangles: Array[GridTriangle]
var quads: Array[GridQuad]

func init(grid_side_size: int, random_seed: int, iteration_count: int):
	if grid_side_size < 2:
		return

	self.side_size = grid_side_size
	self.search_iteration_count = iteration_count
	points.clear()
	triangles.clear()
	quads.clear()

	# points
	for x: int in range(0, side_size * 2 - 1):
		var height: int = (side_size + x) if (x < side_size) else (side_size * 3 - 2 - x)
		# var delta_height: float = (float)side_size - height * 0.5f
		var delta_height: float = self.side_size - height * 0.5
		for y: int in range(0, height):
			var is_side: bool = false
			if x == 0 or x == (self.side_size * 2 - 2) or y == 0 or y == (height - 1):
				is_side = true
			var p = GridPoint.new(Vector2((x - self.side_size + 1) * SIDE_LENGTH, y + delta_height), is_side)
			points.append(p)
	
	# triangles
	var offset: int = 0
	for x in range(0, self.side_size * 2 - 2):
		var height: int = (self.side_size + x) if (x < self.side_size) else (self.side_size * 3 - 2 - x)
		if x < self.side_size - 1:
			# left side
			for y in range(0, height):
				var tri: GridTriangle = GridTriangle.new(offset + y, offset + y + height, offset + y + height + 1, true)
				triangles.append(tri)
				if y >= height - 1:
					break
				tri = GridTriangle.new(offset + y + height + 1, offset + y + 1, offset + y, true)
				triangles.append(tri)
		else:
			# right side
			for y in range(0, height - 1):
				var tri: GridTriangle = GridTriangle.new(offset + y, offset + y + height, offset + y + 1, true)
				triangles.append(tri)
				if y >= height - 2:
					break
				tri = GridTriangle.new(offset + y + 1, offset + y + height, offset + y + height + 1, true)
				triangles.append(tri)
		offset += height

	# triangles to quads
	var tri_index: int
	var adjacents: Array[int]
	var rng = RandomNumberGenerator.new()
	rng.set_seed(random_seed)
	while(true):
		# try up to 'search_iteration_count' times to find a random triangle that's valid
		var search_count: int = 0
		var search_done: bool = false
		while !search_done:
			tri_index = rng.randi() % triangles.size()
			search_count += 1
			if triangles[tri_index].valid or search_count == search_iteration_count:
				search_done = true

		# no valid triangles found. Don't generate any quads
		if search_count == search_iteration_count:
			break
		#print("Triangle ", tri_index)
		adjacents = get_adjacent_triangles(tri_index)
		if adjacents.size() > 0:
			# print("Adjacents ", adjacents)
			var i1: int = tri_index
			var i2: int = adjacents[0]
			var indices: Array[int] = [
				triangles[i1].a, triangles[i1].b, triangles[i1].c,
				triangles[i2].a, triangles[i2].b, triangles[i2].c
			]
			indices.sort()
			var quad_indices: Array[int] = []
			quad_indices.append(indices[0])
			for i in range(1, 6):
				if indices[i] != indices[i-1]:
					quad_indices.append(indices[i])
			if quad_indices.size() != 4:
				print("quad_indices_size ", quad_indices.size()) # better be 4 every time
			var grid_quad: GridQuad = GridQuad.new(quad_indices[0], quad_indices[2], quad_indices[3], quad_indices[1])
			quads.append(grid_quad)
			# mark the two triangles that comprise the quad as 'invalid'
			triangles[tri_index].valid = false
			triangles[adjacents[0]].valid = false

	# quads to 4 quads
	base_quad_count = quads.size()
	var middles: Dictionary = {}
	for i in quads.size():
		var quad: GridQuad = quads[i]
		var q_index: Array[int] = [quad.a, quad.b, quad.c, quad.d]
		var index_center = points.size()
		var midpoint: Vector2 = Vector2(points[quad.a].position + points[quad.b].position + points[quad.c].position + points[quad.d].position)
		midpoint *= 0.25
		var quad_midpoint: GridPoint = GridPoint.new(midpoint, false)
		points.append(quad_midpoint)
		subdivide(q_index, middles, index_center);

	# triangles to 3 quads
	for triangle: GridTriangle in triangles:
		if triangle.valid:
			var t_index: Array[int] = [triangle.a, triangle.b, triangle.c]
			var index_center = points.size()
			var midpoint: Vector2 = Vector2(points[triangle.a].position + points[triangle.b].position + points[triangle.c].position)
			midpoint *= 0.3333
			var tri_midpoint: GridPoint = GridPoint.new(midpoint, false)
			points.append(tri_midpoint)
			subdivide(t_index, middles, index_center);
			
	# point neighbors
	for i in range(base_quad_count, quads.size()): # only look at subdivision quads
		var quad: GridQuad = quads[i]
		var index: Array[int] = [quad.a, quad.b, quad.c, quad.d]

		for p in index:
			if not i in points[p].quads:
				points[p].quads.append(i)
		
		# grab each pair of adjacent points from the quad
		for j in 4:
			var index_1: int = index[j]
			var index_2: int = index[(j + 1) & 3]
			# for the point at index_1, get the list of neighbors, which starts empty
			var good: bool = true
			for k: int in points[index_1].neighbors:
				if k == index_2:
					good = false
					break
			if good:
				points[index_1].neighbors.append(index_2)
				if !points[index_1].quads.has(i): # ABM tell the point that a quad is using it
					points[index_1].quads.append(i)
			
			# for the point at index_2, get the list of neighbors
			# check
			good = true
			for k: int in points[index_2].neighbors:
				if k == index_1:
					good = false
					break
			if good:
				points[index_2].neighbors.append(index_1)
				if !points[index_2].quads.has(i): # ABM tell the point that a quad is using it
					points[index_2].quads.append(i) 

	# quad neighbors
	print("Finding neighbors for quads ", base_quad_count, " - ", quads.size())
	for i in range(base_quad_count, quads.size()): # only look at sub-quads
		var quad: GridQuad = quads[i]
		quad.neighbors = self.get_adjacent_quads(i)


func relax():
	for point in points:
		if point.side:
			continue
		var sum: Vector2 = Vector2.ZERO
		for neighbor in point.neighbors:
			sum += points[neighbor].position
		sum /= (float)(point.neighbors.size())
		point.position = sum


func relax_side():
	var radius: float = (float)(side_size) - 1.0
	var center: Vector2 = Vector2(0.0, (side_size * 2 - 1) * 0.5)
	
	for i in points.size():
		if !points[i].side:
			continue
		var d: Vector2 = points[i].position - center
		var distance = radius - sqrt((d.x * d.x) + (d.y * d.y))
		points[i].position += (d * distance) * 0.1


func world_to_screen(p: Vector2) -> Vector2:
	#var screen_size: Vector2i = DisplayServer.screen_get_size()
	var screen_size: Vector2i = get_window().get_size()
	var ratio: float = screen_size.aspect() # note that I may need the reciprocal
	var res: Vector2 = Vector2(p) / ((float)(side_size * 3.5))
	res.y *= ratio
	res.x *= screen_size.x
	res.y *= screen_size.y
	res += Vector2(screen_size.x / 2.0, 0)
	return res


func subdivide(index: Array[int], middles: Dictionary, index_center: int):
	var count: int = index.size()
	var half_segment_index: Array[int]; # has 'count' elements
	for j: int in count:
		var index_a: int = index[j]
		var index_b: int = index[(j + 1) % count]
		var key: int = (mini(index_a, index_b) << 16) + maxi(index_a, index_b)
		if !middles.has(key):
			half_segment_index.append(points.size())
			var is_side: bool = points[index_a].side && points[index_b].side
			var midpoint_pos: Vector2 = Vector2(points[index_a].position + points[index_b].position)
			midpoint_pos *= 0.5
			var point: GridPoint = GridPoint.new(midpoint_pos, is_side)
			points.append(point)
			middles[key] = half_segment_index[j]
		else:
			half_segment_index.append(middles[key])
	for j: int in count:
		var next_index: int = (j + 1) % count;
		var quad: GridQuad = GridQuad.new(index_center, half_segment_index[j], index[next_index], half_segment_index[next_index])

		var center_pos: Vector2 = points[quad.a].position + points[quad.b].position + points[quad.c].position + points[quad.d].position
		center_pos *= 0.25
		var center_point: GridPoint = GridPoint.new(center_pos, false)
		quad.center = points.size()
		points.append(center_point)
		
		quads.append(quad)


func get_adjacent_triangles(tri_index: int) -> Array[int]:
	var adj: Array[int] = []
	var triangle: GridTriangle = triangles[tri_index]
	var ref: Array[int] = [triangle.a, triangle.b, triangle.c]
	#print("ref: ", ref)

	# check every other valid triangle
	for i in triangles.size():
		if i == tri_index or !triangles[i].valid:
			continue;
		var candidate: GridTriangle = triangles[i]
		var local: Array[int] = [candidate.a, candidate.b, candidate.c]

		var share_count: int = 0
		for j: int in 3:
			for k: int in 3:
				if ref[j] == local[k]:
					share_count += 1
					break
		if share_count >= 3:
			print("share_count should be < 3, is ", share_count)
		# found a triangle that shares two vertices
		if share_count == 2:
			adj.append(i)

	return adj


func get_adjacent_quads(quad_index: int) -> Array[int]:
	var quad: GridQuad = quads[quad_index]
	var quad_position: Vector2 = points[quad.center].position # for cw/ccw calc
	var ref: Array[int] = [quad.a, quad.b, quad.c, quad.d]

	# generate a list of candidate quads by seeing which quads share this one's points
	var candidates: Array[int] = []
	for i in ref:
		var point: GridPoint = points[i]
		for quad_with_point in point.quads:
			if quad_with_point != quad_index:
				if not quad_with_point in candidates:
					candidates.append(quad_with_point)

	var adj: Array[int] = []
	var adj_pos: Array[Vector2] = []

	for i: int in 4:
		# check [a,b] [b,c] [c,d] [d,a] of the central quad
		# Will always end up with neighbors ordered clockwise or counter-clockwise
		var index_1: int = ref[i]
		var index_2: int = ref[(i + 1) % 4]
		for j in candidates:
			var candidate: GridQuad = quads[j]
			var local: Array[int] = [candidate.a, candidate.b, candidate.c, candidate.d]
			# does this quad share two points with the central quad?
			if index_1 in local and index_2 in local:
				adj.append(j)
				adj_pos.append(points[candidate.center].position - quad_position)
				break
	# a quad has 2, 3, or 4 neighbors
	# if there are two neighbors, then the order is both clockwise and counter-clockwise. Do nothing.
	# if there are three neighbors, then the angle between sides may have one greater than 180
	# i.e. one positive cross product and two negative, or two positive and one negative
	# Ignore the outlier to determine clock-wise-ness
	# If there are four neighbors, no angle will be greater than 180, so cross products will be
	# either all positive or all negative
	if adj_pos.size() > 2:
		var sum: int = 0
		for i in adj_pos.size():
			var v1 = adj_pos[i]
			var v2 = adj_pos[(i+1) % adj_pos.size()]
			sum = (sum + 1) if v1.cross(v2) > 0 else (sum - 1)
		if sum < 0:
			adj.reverse()
	return adj

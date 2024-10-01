class_name HexagridRenderer
extends Node2D

var hexagrid: Hexagrid

var draw_positions: bool = false
var draw_sector: bool = false

var highlight_quad: int = -1

@export var side_color: Color = Color(0.18, 0.18, 0.18)
@export var interior_color: Color = Color(.25, .25, .25)
@export var line_color: Color = Color(.7, .7, .7)
@export var triangle_color: Color = Color("A0A0A0")
@export var quad_color: Color = Color("FFFFFF")

var neighbor_index: int = 0
func next_neighbor_index():
	neighbor_index = (neighbor_index + 1) % 4
	
# Rebuild render instructions with CanvasItem.queue_redraw()
func _draw():
	if hexagrid == null:
		return
	if draw_positions:
		for point in hexagrid.points:
			draw_circle(hexagrid.world_to_screen(point.position), 5, side_color if point.side else interior_color)
	
	if draw_sector:
		var a: Vector2
		var b: Vector2
		var c: Vector2
		var d: Vector2
		for triangle in hexagrid.triangles:
			if triangle.valid:
				var tri_array : PackedVector2Array = []
				a = hexagrid.world_to_screen(hexagrid.points[triangle.a].position)
				b = hexagrid.world_to_screen(hexagrid.points[triangle.b].position)
				c = hexagrid.world_to_screen(hexagrid.points[triangle.c].position)
				tri_array.append(a)
				tri_array.append(b)
				tri_array.append(c)
				tri_array.append(a)
				draw_polyline(tri_array, triangle_color )
		for quad in hexagrid.quads:
			var quad_array : PackedVector2Array = []
			a = hexagrid.world_to_screen(hexagrid.points[quad.a].position)
			b = hexagrid.world_to_screen(hexagrid.points[quad.b].position)
			c = hexagrid.world_to_screen(hexagrid.points[quad.c].position)
			d = hexagrid.world_to_screen(hexagrid.points[quad.d].position)
			quad_array.append(a)
			quad_array.append(b)
			quad_array.append(c)
			quad_array.append(d)
			quad_array.append(a)
			draw_polyline(quad_array, quad_color)
			
	else:
		for point in hexagrid.points:
			var screen_point: Vector2 = hexagrid.world_to_screen(point.position)
			for neighbor_point_index in point.neighbors:
				var neighbor_point = hexagrid.points[neighbor_point_index]
				var neighbor_screen_point = hexagrid.world_to_screen(neighbor_point.position)
				draw_line(screen_point, neighbor_screen_point, line_color, 2)

	if self.highlight_quad > 0:
		var quad = hexagrid.quads[highlight_quad]
		var quad_array : PackedVector2Array = []
		var a = hexagrid.world_to_screen(hexagrid.points[quad.a].position)
		var b = hexagrid.world_to_screen(hexagrid.points[quad.b].position)
		var c = hexagrid.world_to_screen(hexagrid.points[quad.c].position)
		var d = hexagrid.world_to_screen(hexagrid.points[quad.d].position)
		quad_array.append(a)
		quad_array.append(b)
		quad_array.append(c)
		quad_array.append(d)
		draw_polygon(quad_array, [quad_color])

		#print(quad.neighbors)
		for i in quad.neighbors.size():
			var nq = quad.neighbors[i]
			#print(nq)
			var nquad = hexagrid.quads[nq]
			var nquad_array : PackedVector2Array = []
			var na = hexagrid.world_to_screen(hexagrid.points[nquad.a].position)
			var nb = hexagrid.world_to_screen(hexagrid.points[nquad.b].position)
			var nc = hexagrid.world_to_screen(hexagrid.points[nquad.c].position)
			var nd = hexagrid.world_to_screen(hexagrid.points[nquad.d].position)
			nquad_array.append(na)
			nquad_array.append(nb)
			nquad_array.append(nc)
			nquad_array.append(nd)
			#print(nquad_array)
			var color = side_color if i == self.neighbor_index else triangle_color
			draw_polygon(nquad_array, [color])

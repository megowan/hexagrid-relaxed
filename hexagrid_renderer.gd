class_name HexagridRenderer
extends Node2D

var hexagrid: Hexagrid

var draw_positions: bool = false
var draw_sector: bool = false

@export var side_color: Color = Color(0.18, 0.18, 0.18)
@export var interior_color: Color = Color(.25, .25, .25)
@export var line_color: Color = Color(.7, .7, .7)
@export var triangle_color: Color = Color("A0A0A0")
@export var quad_color: Color = Color("FFFFFF")


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

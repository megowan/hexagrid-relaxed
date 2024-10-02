class_name Main
extends Node2D
# TODO
# add the concept of a neighboring quad to a given quad
# come up with a means to sort quad neighbors clockwise (or CCW)
# can I reduce the number of lines drawn?

@onready var hexagrid: Hexagrid = $Hexagrid
@onready var hexagrid_renderer: HexagridRenderer = $HexagridRenderer

@onready var sides_slider: HSlider = $VFlowContainer/Sides_Container/Sides_Slider
@onready var sides_value_label: Label = $VFlowContainer/Sides_Container/Sides_Value_Label
@onready var seed_slider: HSlider = $VFlowContainer/Seed_Container/Seed_Slider
@onready var grouping_slider: HSlider = $VFlowContainer/Grouping_Container/Grouping_Slider
@onready var grouping_value_label: Label = $VFlowContainer/Grouping_Container/Grouping_Value_Label
@onready var relax_check: CheckBox = $VFlowContainer/Relax_Check
@onready var relax_side_check: CheckBox = $VFlowContainer/Relax_Side_Check
@onready var draw_point_check: CheckBox = $VFlowContainer/Draw_Point_Check
@onready var draw_sectors_check: CheckBox = $VFlowContainer/Draw_Sectors_Check

var side_count: int = 6
var random_seed: int = 1337
var grouping: int = 6
var relax_it : bool = false
var relax_side: bool = false
var draw_positions: bool = false
var draw_sector: bool = false

# When side_count, seed, grouping, relax_it, relax_side change, then re_initialize hexagrid
# If draw_positions and draw_sector change, then just queue a redraw
var is_dirty: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sides_slider.value = side_count
	sides_value_label.text = str(side_count)
	seed_slider.value = random_seed
	grouping_slider.value = grouping
	grouping_value_label.text = str(grouping)
	
	if hexagrid != null:
		hexagrid_renderer.hexagrid = hexagrid
		hexagrid_renderer.draw_positions = draw_positions
		hexagrid_renderer.draw_sector = draw_sector
		hexagrid.init(side_count, random_seed, grouping)
		hexagrid_renderer.queue_redraw()

var timer: float = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta * 15.0 # 15 fps
	if timer > 1:
		timer -= 1.0
		if relax_it:
			hexagrid.relax()
			if relax_side:
				hexagrid.relax_side()
			hexagrid_renderer.queue_redraw()

	if is_dirty:
		hexagrid.init(side_count, random_seed, grouping)
		hexagrid_renderer.queue_redraw()
		is_dirty = false


func _on_sides_slider_value_changed(value: float) -> void:
	sides_value_label.text = str(int(value))


func _on_sides_slider_drag_ended(_value_changed: bool) -> void:
	side_count = int(sides_slider.value)
	is_dirty = true
	print("New side count is ", side_count)


func _on_seed_slider_drag_ended(_value_changed: bool) -> void:
	random_seed = int(seed_slider.value)
	is_dirty = true
	print("New seed is ", random_seed)


func _on_grouping_slider_value_changed(value: float) -> void:
	grouping_value_label.text = str(int(value))


func _on_grouping_slider_drag_ended(_value_changed: bool) -> void:
	grouping = int(grouping_slider.value)
	is_dirty = true
	print("New grouping is ", grouping)


func _on_relax_check_toggled(toggled_on: bool) -> void:
	relax_it = toggled_on
	print("Relax is ", relax_it)
	relax_side_check.visible = relax_it
	is_dirty = true


func _on_relax_side_check_toggled(toggled_on: bool) -> void:
	relax_side = toggled_on
	print("Relax_side is ", relax_side)
	is_dirty = true


func _on_draw_point_check_toggled(toggled_on: bool) -> void:
	draw_positions = toggled_on
	print("Draw points is ", draw_positions)
	hexagrid_renderer.draw_positions = draw_positions
	hexagrid_renderer.queue_redraw()


func _on_draw_sectors_check_toggled(toggled_on: bool) -> void:
	draw_sector = toggled_on
	print("Draw sectors is ", draw_sector)
	hexagrid_renderer.draw_sector = draw_sector
	hexagrid_renderer.queue_redraw()

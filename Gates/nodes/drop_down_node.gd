tool
extends Node2D

#variables for circle
var circle_radius = 40
var circle_color = Color.black
var original_invalid_color #used when hovering over a gate to turn it red if you're dragging the mouse while entering
var circle_position = Vector2.ZERO #where circle originates from

#variables for line drawn
var line_end = Vector2.ZERO #where the line ends
var line_start = Vector2.ZERO #where the line starts
var hovered_over = false #stores whether cursor is hovering over line node
var is_connected = false
var connected_node = null #node that this node connects to

#load line from memory
onready var line = get_node("line")

var offset: Vector2

var draggable = false

#ensure gates of the same type can't connect to each other
var gate_type

# Called when the node enters the scene tree for the first time.
func _ready():
	#initialize first two points
	set_gate_type()
	print(gate_type)
	line.add_point(Vector2.ZERO)
	line.add_point(Vector2.ZERO)
	update()

func set_gate_type():
	pass

#drawing is very problematic, so I'm clobbering together a quick fix
func _draw():
	line.clear_points()
	line.add_point(line_start)
	line.add_point(line_end)
	draw_circle(circle_position, circle_radius, circle_color)
		

#change circle color, reset circle position (just in case)
func change_circle_color(new_color: Color):
	circle_position = Vector2.ZERO
	circle_color = new_color
	update()

#change where line starts from
#this is when finishing drawing a line
#this is not good code, but I don't care enough
func change_line_start(new_line_start: Vector2):
	line_start = new_line_start
	update()

#draw connecting line from circle
func draw_connecting_line(mouse_position: Vector2):
	line_end = mouse_position
	update()

#automatically changes the color if circle entered / exited
#this is only called if a line isn't actively being drawn
func _on_Area2D_mouse_entered():
	hovered_over = true
	#check if color was changed
	if not global.is_dragging and not global.node_selected:
		print("area entered")
		if not Input.is_action_pressed("left_click"):
			change_circle_color(Color.white)
			print("enabling dragging")
			global.node_selected = true
			draggable = true
		else:
			#visually show that this node can't be selected
			#save original circle color
			original_invalid_color = circle_color
			change_circle_color(Color.darkred)
	

#reset variable and colors
func reset_circle():
	global.node_selected = false
	draggable = false
	change_circle_color(Color.black)

func _on_Area2D_mouse_exited():
	hovered_over = false
	#print(original_invalid_color)
	if original_invalid_color:
		#print(circle_color)
		circle_color = original_invalid_color
		original_invalid_color = null
		change_circle_color(circle_color)
	if not global.is_dragging and not connected_node:
		reset_circle()

func _physics_process(delta):
	if draggable:
		if Input.is_action_just_pressed("left_click"):
			print("pressed start")
			if connected_node:
				#reset this node and connected node
				#but keep this one set as white
				connected_node.reset_circle()
				connected_node.change_line_start(circle_position)
				connected_node.draw_connecting_line(circle_position)
				change_line_start(circle_position)
				draw_connecting_line(circle_position)
				connected_node.connected_node = null
				connected_node = null
			#make current 
			global.is_dragging = true
		if Input.is_action_pressed("left_click"):
			offset = get_global_mouse_position() - global_position
			draw_connecting_line(offset)
			#variable storing whether a member is already connected
			#ensures only one member can be connected to
			var no_connecting_members = true
			for member in get_tree().get_nodes_in_group("line_node"):
				if member != self and member.gate_type != self.gate_type:
					if member.hovered_over:
						#if so, check if it is currently being hovered over
						if no_connecting_members:
							connected_node = member
							no_connecting_members = false
							member.change_circle_color(Color.white)
					#otherwise, reset the color
					elif member.connected_node:
						member.change_circle_color(Color.white)
					elif not member.connected_node:
						member.change_circle_color(Color.black)
			if no_connecting_members:
				connected_node = null
			
		if Input.is_action_just_released("left_click"):
			print("released")
			global.is_dragging = false
			if connected_node:
				#draw line from center of this node to edge of other node
				offset = connected_node.global_position - global_position
				var offset_in_circle = offset.normalized() * circle_radius
				
				offset = offset - offset_in_circle
				connected_node.change_circle_color(Color.white)
				change_line_start(offset_in_circle)
				draw_connecting_line(offset)
				
				if connected_node.connected_node and connected_node.connected_node != self:
					#this looks ridiculous, but trust me it works
					if connected_node.connected_node.connected_node:
						connected_node.connected_node.connected_node = null
					#reset any secondary connected nodes connected to the connected node
					connected_node.connected_node.draw_connecting_line(circle_position)
					connected_node.connected_node.reset_circle()
					connected_node.connected_node = null
				
				#delete any line it may connect to
				connected_node.draw_connecting_line(circle_position)
				connected_node.connected_node = self
				
				#turn off draggable for these nodes
				draggable = false
				hovered_over = false
				connected_node.draggable = false
				global.node_selected = false
				connected_node.hovered_over = false
			else:
				reset_circle()
				draw_connecting_line(circle_position)
				draggable = false
				global.node_selected = false

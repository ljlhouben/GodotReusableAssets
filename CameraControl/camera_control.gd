# Copyright (c) 2024, Ludo Houben <ljlhouben@gmail.com>, 
# This work is licensed under CC BY-SA 4.0.
# To view a copy of this license, visit https://creativecommons.org/licenses/by-sa/4.0/
#
# If you like my work than I would appreciate receiving a coffee
# https://www.buymeacoffee.com/ljlhouben
#
# VERSION: 1.0
# DESCRPTION:
#     This script operates a camera in a 'Transport Fever' way. And can be controlled by keys,
#     mouse and mousepad. Following features are implemented:
#     - Movement LEFT/DOWN/UP/RIGHT (keys: 'A/S/W/D' / mouse[pad]: left/down/up/right with right button)
#     - Pan CCW/CW (keys: 'Q/E' / mouse[pad]: left/right with middle button [key 'CTRL'])
#     - Tilt UP/DOWN (keys: 'R/F' / mouse[pad]: up/down with middle button [key 'CTRL'])
#     - Zoom OUT/IN (keys: 'Z/X' / mouse[pad]: scroll up/down [2 point pinch/release])
#     - Interlocking of contradictional movements
#     - Optional edge scrolling LEFT/DOWN/UP/RIGHT and debug information
#     - Configurable speeds/initial positions/limits/inversion of movement direction
#
# INPUT MAPPING:
#     ui_up [key W] / ui_down [key S] / ui_left [key A] / ui_right [key D]
#     ui_zoom_in [key Z] / ui_zoom_out [key X]
#     ui_pan_left [key Q] / ui_pan_right [key E]
#     ui_tilt_forward [key R] / ui_tilt_backward [key F]
#     mouse_btn_left / mouse_btn_middle [key CTRL] / mouse_btn_right
#     mouse_wheel_up / mouse_wheel_down
#     NOTE: Couple the mouse buttons as 'all devices'
#
# MODEFICATION HISTORY:
#    v1.0: Initial version based on Godot v4.3

extends Node3D

enum E_MOUSE_ACTION_STATES {
	IDLE,
	MOVE_AND_DRAG,
	PAN_AND_TILT,
}

# Generic
@export var CfgShowDebugInfo : bool = false
@export var CfgMouseSensitivity : float = 1.0

# Zooming
@export var CfgZoomInvertDirection : bool = false
@export var CfgZoomSpeed : float = 1
@export var CfgZoomInitDistance : float = 10
@export var CfgZoomMaxIn : float = 5.0
@export var CfgZoomMaxOut : float = 100.0
@export var CfgZoomScrollFactor : float = 5.0

# Moving
@export var CfgMoveInvertDirection : bool = false
@export var CfgMoveSpeed : float = 1
@export var CfgMoveInitPos : Vector2 = Vector2(0,5)
@export var CfgMoveEnableSideMoving : bool = true
@export var CfgMoveSideMovingThreshold : float = 20.0

# Panning
@export var CfgPanInvertDirection : bool = false
@export var CfgPanSpeed : float = 1

# Tilting
@export var CfgTiltInvertDirection : bool = false
@export var CfgTiltSpeed : float = 1
@export var CfgTiltInitAngle : float = 25
@export var CfgTiltMinAngle : float = 5.0
@export var CfgTiltMaxAngle : float = 80.0

var ActualMouseState : E_MOUSE_ACTION_STATES = E_MOUSE_ACTION_STATES.IDLE
var ActualZoomDistance : float
var ActualZoomspeed : float
var ActualMoveSpeed : float
var ActualPanSpeed : float
var ActualTiltSpeed : float
var ActualTiltAngle : float
var PreviousZoomDistance : float

func _ready():
	global_position = Vector3(0, 0, 0)
	ActualZoomDistance = CfgZoomInitDistance
	ActualTiltAngle = CfgTiltInitAngle
	$Camera.rotation.x = -deg_to_rad(ActualTiltAngle)
	$Camera.position = Vector3(CfgMoveInitPos.x, CfgMoveInitPos.y, ActualZoomDistance)
	$Camera.position = Vector3($Camera.position.x, -(ActualZoomDistance * sin($Camera.rotation.x)), (ActualZoomDistance * cos($Camera.rotation.x)))

func _process(delta):
	var viewPortSize = get_viewport().size
	var mousePos = get_viewport().get_mouse_position()
	
# Mouse action state handling
	if not Input.is_action_pressed("mouse_btn_middle") and Input.is_action_pressed("mouse_btn_right"):
		ActualMouseState = E_MOUSE_ACTION_STATES.MOVE_AND_DRAG
	elif Input.is_action_pressed("mouse_btn_middle") and not Input.is_action_pressed("mouse_btn_right"):
		ActualMouseState = E_MOUSE_ACTION_STATES.PAN_AND_TILT
	elif Input.is_action_just_released("mouse_btn_middle") or Input.is_action_just_released("mouse_btn_right"):
		ActualMouseState = E_MOUSE_ACTION_STATES.IDLE
	
# Zoom handling
	ActualZoomspeed = CfgZoomSpeed * 10 * (ActualZoomDistance / CfgZoomMaxIn) * delta
	if  CfgZoomInvertDirection:
		ActualZoomspeed = ActualZoomspeed * -1
	
	if Input.is_action_just_released("mouse_wheel_up") and not Input.is_action_pressed("ui_zoom_out"):
		ActualZoomDistance -= ActualZoomspeed * CfgZoomScrollFactor
	
	if Input.is_action_pressed("ui_zoom_in") \
			and not (Input.is_action_pressed("ui_zoom_out") or Input.is_action_just_released("mouse_wheel_down")):
		ActualZoomDistance -= ActualZoomspeed
	
	if Input.is_action_just_released("mouse_wheel_down") and not Input.is_action_pressed("ui_zoom_in"):
		ActualZoomDistance += ActualZoomspeed * CfgZoomScrollFactor
	
	if Input.is_action_pressed("ui_zoom_out") \
			and not (Input.is_action_pressed("ui_zoom_in") or Input.is_action_just_released("mouse_wheel_up")):
		ActualZoomDistance += ActualZoomspeed
	ActualZoomDistance = clamp(ActualZoomDistance, CfgZoomMaxIn, CfgZoomMaxOut)
	
# Move handling
	ActualMoveSpeed = -CfgMoveSpeed * 10 * ((ActualZoomDistance * CfgZoomMaxOut) / (CfgZoomMaxIn * CfgZoomMaxOut)) * delta
	global_position.x -= cos(rotation.y) * KeyAndMouseCtrl(ActualMoveSpeed, "ui_left", "ui_right", CfgMoveInvertDirection, \
										ActualMouseState == E_MOUSE_ACTION_STATES.MOVE_AND_DRAG, \
										(0.0025 * CfgMouseSensitivity)).Xvalue
	
	global_position.z += sin(rotation.y) * KeyAndMouseCtrl(ActualMoveSpeed, "ui_left", "ui_right", CfgMoveInvertDirection, \
										ActualMouseState == E_MOUSE_ACTION_STATES.MOVE_AND_DRAG, \
										(0.0025 * CfgMouseSensitivity)).Xvalue
	
	global_position.x -= sin(rotation.y) * KeyAndMouseCtrl(ActualMoveSpeed, "ui_up", "ui_down", CfgMoveInvertDirection, \
										ActualMouseState == E_MOUSE_ACTION_STATES.MOVE_AND_DRAG, \
										(0.0025 * CfgMouseSensitivity)).Yvalue
	
	global_position.z -= cos(rotation.y) * KeyAndMouseCtrl(ActualMoveSpeed, "ui_up", "ui_down", CfgMoveInvertDirection, \
										ActualMouseState == E_MOUSE_ACTION_STATES.MOVE_AND_DRAG, \
										(0.0025 * CfgMouseSensitivity)).Yvalue
	
# Edge scrolling
	if CfgMoveEnableSideMoving and ActualMouseState == E_MOUSE_ACTION_STATES.IDLE \
			and not (Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") \
				or Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right")):
		if mousePos.x >= 0 and mousePos.x <= CfgMoveSideMovingThreshold:
			global_position.x += ActualMoveSpeed * cos(rotation.y)
			global_position.z -= ActualMoveSpeed * sin(rotation.y)
		
		if mousePos.x >= (viewPortSize.x - CfgMoveSideMovingThreshold) and mousePos.x <= viewPortSize.x:
			global_position.x -= ActualMoveSpeed * cos(rotation.y)
			global_position.z += ActualMoveSpeed * sin(rotation.y)
		
		if mousePos.y >= 0 and mousePos.y <= CfgMoveSideMovingThreshold:
			global_position.x += ActualMoveSpeed * sin(rotation.y)
			global_position.z += ActualMoveSpeed * cos(rotation.y)
		
		if mousePos.y >= (viewPortSize.y - CfgMoveSideMovingThreshold)and mousePos.y <= viewPortSize.y:
			global_position.x -= ActualMoveSpeed * sin(rotation.y)
			global_position.z -= ActualMoveSpeed * cos(rotation.y)
	
# Pan handling
	ActualPanSpeed = CfgPanSpeed * 1.5 * delta
	rotate_y(KeyAndMouseCtrl(ActualPanSpeed, "ui_pan_left", "ui_pan_right", CfgPanInvertDirection, \
										ActualMouseState == E_MOUSE_ACTION_STATES.PAN_AND_TILT, \
										(0.0025 * CfgMouseSensitivity)).Xvalue)
	
# Tilt handling
	ActualTiltSpeed = CfgTiltSpeed * 100 * delta
	ActualTiltAngle += (KeyAndMouseCtrl(ActualTiltSpeed, "ui_tilt_forward", "ui_tilt_backward", CfgTiltInvertDirection, \
										ActualMouseState == E_MOUSE_ACTION_STATES.PAN_AND_TILT, \
										(0.0025 * CfgMouseSensitivity)).Yvalue)
	ActualTiltAngle = clamp(ActualTiltAngle, CfgTiltMinAngle, CfgTiltMaxAngle)
	$Camera.rotation.x = -deg_to_rad(ActualTiltAngle + (((CfgTiltMaxAngle - CfgTiltMinAngle)/2) * (ActualZoomDistance/CfgZoomMaxOut)))
	
# Update camera position
	$Camera.rotation.x = clamp($Camera.rotation.x, -deg_to_rad(CfgTiltMaxAngle), -deg_to_rad(CfgTiltMinAngle))
	$Camera.position = Vector3($Camera.position.x, -(ActualZoomDistance * sin($Camera.rotation.x)), (ActualZoomDistance * cos($Camera.rotation.x)))
	
# Debug info
	$DebugInfo.text = "FPS: " + str(Engine.get_frames_per_second()) \
					+ "\n" + "Actual move speed: " + str(abs(ActualMoveSpeed)) \
					+ "\n" + "Actual zoom distance: " + str(abs(ActualZoomDistance)) \
					+ "\n" + "Prev zoom distance: " + str(PreviousZoomDistance) \
					+ "\n" + "Actual pan angle: " + str(rad_to_deg(rotation.y)) \
					+ "\n" + "Actual tilt angle: " + str(ActualTiltAngle) \
					+ "\n" + "Actual camera angle: " + str(rad_to_deg(abs($Camera.rotation.x))) \
					+ "\n" + "Left mouse clicked: " + str(Input.is_action_pressed("mouse_btn_left")) \
					+ "\n" + "Middle mouse clicked: " + str(Input.is_action_pressed("mouse_btn_middle")) \
					+ "\n" + "Right mouse clicked: " + str(Input.is_action_pressed("mouse_btn_right")) 
	$DebugInfo.visible = CfgShowDebugInfo

func KeyAndMouseCtrl(Value : float, KeyNegative : String, KeyPositive : String, InvertDirection : bool, MouseActive : bool, MouseSensitivity : float):
	var Status = {"Xvalue" : 0.0, "Yvalue" : 0.0}
	
	if MouseActive and InputEventMouseMotion \
			and not (Input.is_action_pressed(KeyNegative) or Input.is_action_pressed(KeyPositive)):
		Status.Xvalue = Value * Input.get_last_mouse_velocity().x * MouseSensitivity
		Status.Yvalue = Value * Input.get_last_mouse_velocity().y * MouseSensitivity
	
	if Input.is_action_pressed(KeyNegative) and not (MouseActive or Input.is_action_pressed(KeyPositive)):
		Status.Xvalue = -Value
		Status.Yvalue = -Value
	
	if Input.is_action_pressed(KeyPositive) and not (MouseActive or Input.is_action_pressed(KeyNegative)):
		Status.Xvalue = Value
		Status.Yvalue = Value
	
	if InvertDirection:
		Status.Xvalue = -Status.Xvalue
		Status.Yvalue = -Status.Yvalue
	
	return Status

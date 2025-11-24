extends Node3D

var skins = {
	"praknur" = load("res://assety/tekstury/puszka/texture_praknur.png"),
	"knur" = load("res://assety/tekstury/puszka/texture_knur.png"),
	"hanys" = load("res://assety/tekstury/puszka/texture_hanys.png"),
	"lech" = load("res://assety/tekstury/puszka/texture_lech.png"),
	"zyniec" = load("res://assety/tekstury/puszka/texture_zyniec.png"),
	"tyskie" = load("res://assety/tekstury/puszka/texture.png")
}

@export var myskin = ""
@onready var mesh = $Cylinder
var outline_color :Color = Color(0,0,0)
var outline_thickness = 0.05
func _ready() -> void:
	update_skin()

func update_skin():
	if not skins.has(myskin):
		myskin = "tyskie"

	var tex: Texture2D = skins[myskin]
	
	var mat : Material = mesh.get_active_material(0)
	mat = mat.duplicate(true)
	mesh.set_surface_override_material(0, mat)
	
	if mat == null:
		push_warning("Mesh nie ma materiału na surface 0")
		return
	mat.set_shader_parameter("color", outline_color)
	mat.set_shader_parameter("thickness", outline_thickness)
	var next_mat : StandardMaterial3D = mat.next_pass
	if next_mat is StandardMaterial3D:
		next_mat.albedo_texture = tex
	else:
		push_warning("Materiał nie jest ShaderMaterial — nie mogę ustawić parametru shadera.")

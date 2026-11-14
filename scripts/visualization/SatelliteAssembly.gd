extends Node3D
## Shared presentation assembly. Never interprets geometry as engineering capability.
const ADAPTER = preload("res://data/mock/SatelliteAdapter.gd")
var selected_ids: Dictionary = {}
var satellite_id = ""
func _ready() -> void:
	if selected_ids.is_empty(): configure(ADAPTER.STARTER)
func configure(draft: Dictionary) -> void:
	satellite_id = "kit"
	for key in ADAPTER.STARTER:
		var id = draft.get(key, ADAPTER.STARTER[key])
		if selected_ids.get(key) == id: continue
		var old = get_node_or_null(NodePath(key))
		if old:
			remove_child(old)
			old.queue_free()
		var slot = Node3D.new()
		slot.name = key
		slot.scale = Vector3.ONE * 35.0
		add_child(slot)
		var asset = ""
		for option in ADAPTER.catalog(key):
			if option.id == id: asset = option.asset
		var packed = load(asset) if not asset.is_empty() and ResourceLoader.exists(asset) else null
		if packed is PackedScene:
			slot.add_child(packed.instantiate())
		else:
			var placeholder = MeshInstance3D.new()
			var mesh = BoxMesh.new()
			mesh.size = Vector3.ONE * 0.02
			placeholder.mesh = mesh
			slot.add_child(placeholder)
		if key == "wings_id":
			slot.scale = Vector3(24.0, 24.0, 24.0)
			for part in slot.find_children("*", "MeshInstance3D", true, false):
				if "Wing" in str(part.name) and not "Connector" in str(part.name):
					var solar = ShaderMaterial.new()
					solar.shader = preload("res://assets/3d/materials/SatelliteSolar.gdshader")
					part.material_override = solar
		if key == "body_id":
			var bounds = AABB()
			var first = true
			for part in slot.find_children("*", "MeshInstance3D", true, false):
				var local = slot.global_transform.affine_inverse() * part.global_transform * part.get_aabb()
				bounds = local if first else bounds.merge(local)
				first = false
			var factor = 1.25 / maxf(0.001, maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z)))
			slot.scale = Vector3.ONE * factor
			slot.position = -bounds.get_center() * factor
		selected_ids[key] = id
	align_parts()

func clear_model() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	selected_ids.clear()

func align_parts() -> void:
	var body = get_node_or_null("body_id")
	var radio = get_node_or_null("radio_id")
	if not body or not radio: return
	var top = -INF
	for part in body.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = global_transform.affine_inverse() * part.global_transform * part.get_aabb()
		top = maxf(top, box.end.y)
	radio.position.y = 0
	var bottom = INF
	for part in radio.find_children("*", "MeshInstance3D", true, false):
		var box: AABB = global_transform.affine_inverse() * part.global_transform * part.get_aabb()
		bottom = minf(bottom, box.position.y)
	if is_finite(top) and is_finite(bottom): radio.position.y = top - bottom - 0.04

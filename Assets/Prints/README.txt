Asset pipeline (Phase 2 / 5)
-----------------------------
Drop optional visuals per unit:

  res://Assets/Prints/<unit_id>/model.gltf

Example: unit id "001" -> Assets/Prints/001/model.gltf

If missing, battle/hub use placeholder UI (no crash).
See Systems/PrintMeshResolver.gd.

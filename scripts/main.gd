extends Node2D
## 부트스트랩 씬. 환경 검증용이며 기획 확정 후 실제 게임 루트로 교체한다.


func _ready() -> void:
	print("ProjectC booted on Godot %s" % Engine.get_version_info().string)

extends SceneTree
## NameGenerator 확인용 헤드리스 스크립트.
##
##   godot --headless --path . --script res://tools/test_name_generator.gd
##
## 검증 항목
##   1. 같은 시드 → 같은 결과 (GDD 1.2 결정론)
##   2. 다른 시드 → 다른 결과
##   3. 세대별로 이름 느낌이 갈리는가
##   4. 성씨 분포가 실제와 비슷한가
##   5. 동명이인 회피가 작동하는가


func _init() -> void:
	print("=== 1. 결정론: 같은 시드 두 번 ===")
	var a: Array[String] = _roster(12345)
	var b: Array[String] = _roster(12345)
	print("  seed 12345 (1회): ", ", ".join(a))
	print("  seed 12345 (2회): ", ", ".join(b))
	print("  일치: ", "OK" if a == b else "FAIL")

	print("")
	print("=== 2. 다른 시드 ===")
	print("  seed 99999      : ", ", ".join(_roster(99999)))

	print("")
	print("=== 3. 세대별 (각 8명) ===")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for age in [58, 48, 38, 28]:
		var names: PackedStringArray = []
		for _i in 8:
			names.append(str(NameGenerator.generate(rng, age, 2026)["full"]))
		print("  %d세 (%d년대생): %s" % [age, _decade_of(age), ", ".join(names)])

	print("")
	print("=== 4. 성씨 분포 (2000명) ===")
	rng.seed = 42
	var counts: Dictionary = {}
	for _i in 2000:
		var s: String = str(NameGenerator.generate(rng, 40, 2026)["surname"])
		counts[s] = int(counts.get(s, 0)) + 1
	var pairs: Array = []
	for k in counts:
		pairs.append([k, counts[k]])
	pairs.sort_custom(func(x, y): return x[1] > y[1])
	var top: PackedStringArray = []
	for i in min(8, pairs.size()):
		top.append("%s %.1f%%" % [pairs[i][0], pairs[i][1] / 20.0])
	print("  상위 8: ", ", ".join(top))
	print("  등장 성씨 수: ", counts.size())

	print("")
	print("=== 5. 동명이인 회피 (같은 나이 30명) ===")
	rng.seed = 1
	var ages: Array[int] = []
	for _i in 30:
		ages.append(40)
	var many: Array[Dictionary] = NameGenerator.generate_many(rng, 30, ages, 2026)
	var seen: Dictionary = {}
	var dup: int = 0
	for n in many:
		if seen.has(n["full"]):
			dup += 1
		seen[n["full"]] = true
	print("  생성 30명, 중복 ", dup, "건")
	var sample: PackedStringArray = []
	for i in 10:
		sample.append(str(many[i]["full"]))
	print("  예시: ", ", ".join(sample))

	quit()


func _roster(s: int) -> Array[String]:
	var rng := RandomNumberGenerator.new()
	rng.seed = s
	var out: Array[String] = []
	for _i in 6:
		out.append(str(NameGenerator.generate(rng, 40, 2026)["full"]))
	return out


func _decade_of(age: int) -> int:
	return int(floor((2026 - age) / 10.0)) * 10

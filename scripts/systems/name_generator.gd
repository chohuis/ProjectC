class_name NameGenerator
extends RefCounted
## 한국어 인명 생성기.
##
## 시뮬레이션 층에 속한다 — Godot 노드에 의존하지 않는다 (GDD 1.1).
## 모든 난수는 호출자가 넘긴 RandomNumberGenerator 에서만 뽑는다 (GDD 1.2 결정론).
## 같은 시드 + 같은 호출 순서 = 같은 결과.

## 성씨. 실제 분포를 반영해 가중치를 준다.
## 김·이·박이 전체의 약 45%를 차지하므로 한 팀에 동성이 겹치는 것이 자연스럽다
## → 별명이 필요해지는 이유가 된다 (GDD 2.1).
const SURNAMES: Array[Dictionary] = [
	{"n": "김", "w": 215}, {"n": "이", "w": 147}, {"n": "박", "w": 84},
	{"n": "최", "w": 48}, {"n": "정", "w": 44}, {"n": "강", "w": 24},
	{"n": "조", "w": 21}, {"n": "윤", "w": 20}, {"n": "장", "w": 19},
	{"n": "임", "w": 17}, {"n": "한", "w": 15}, {"n": "오", "w": 15},
	{"n": "서", "w": 14}, {"n": "신", "w": 13}, {"n": "권", "w": 13},
	{"n": "황", "w": 13}, {"n": "안", "w": 13}, {"n": "송", "w": 12},
	{"n": "전", "w": 11}, {"n": "홍", "w": 11}, {"n": "유", "w": 10},
	{"n": "고", "w": 9}, {"n": "문", "w": 9}, {"n": "양", "w": 9},
	{"n": "손", "w": 9}, {"n": "배", "w": 8}, {"n": "백", "w": 7},
	{"n": "허", "w": 7}, {"n": "남", "w": 6}, {"n": "심", "w": 6},
	{"n": "노", "w": 6}, {"n": "하", "w": 5}, {"n": "곽", "w": 4},
	{"n": "성", "w": 4}, {"n": "차", "w": 4}, {"n": "주", "w": 4},
	{"n": "우", "w": 4}, {"n": "구", "w": 4}, {"n": "민", "w": 3},
	{"n": "류", "w": 3}, {"n": "나", "w": 3}, {"n": "진", "w": 3},
	{"n": "지", "w": 3}, {"n": "엄", "w": 3}, {"n": "채", "w": 3},
	{"n": "원", "w": 3}, {"n": "천", "w": 3}, {"n": "방", "w": 2},
	{"n": "공", "w": 2}, {"n": "현", "w": 2}, {"n": "함", "w": 2},
	{"n": "변", "w": 2}, {"n": "염", "w": 2}, {"n": "여", "w": 2},
	{"n": "추", "w": 2}, {"n": "도", "w": 2}, {"n": "석", "w": 2},
	{"n": "선", "w": 2}, {"n": "설", "w": 1}, {"n": "마", "w": 1},
	{"n": "길", "w": 1}, {"n": "연", "w": 1}, {"n": "위", "w": 1},
	{"n": "표", "w": 1}, {"n": "명", "w": 1}, {"n": "기", "w": 1},
	{"n": "반", "w": 1}, {"n": "왕", "w": 1}, {"n": "금", "w": 1},
	{"n": "옥", "w": 1}, {"n": "육", "w": 1}, {"n": "인", "w": 1},
	{"n": "맹", "w": 1}, {"n": "제", "w": 1}, {"n": "모", "w": 1},
	{"n": "탁", "w": 1}, {"n": "국", "w": 1}, {"n": "어", "w": 1},
	{"n": "은", "w": 1}, {"n": "편", "w": 1}, {"n": "용", "w": 1},
]

## 세대별 이름 음절 풀.
## 이름만 봐도 나이대가 느껴지게 하는 것이 목적이다 (GDD 2.11 나이 위계).
## 키는 출생 연대(10년 단위).
const GIVEN_SYLLABLES: Dictionary = {
	1960: {
		"first": ["영", "정", "성", "광", "병", "재", "경", "동", "상", "명",
				  "종", "만", "기", "용", "태", "창", "학", "규", "일", "진"],
		"second": ["수", "호", "철", "식", "근", "환", "석", "국", "표", "복",
				   "남", "규", "선", "웅", "배", "덕", "길", "출", "택", "완"],
	},
	1970: {
		"first": ["상", "진", "경", "성", "재", "정", "동", "용", "태", "승",
				  "종", "광", "영", "규", "현", "일", "준", "민", "창", "형"],
		"second": ["현", "우", "호", "석", "훈", "수", "민", "철", "환", "규",
				   "식", "원", "찬", "범", "혁", "진", "택", "표", "권", "선"],
	},
	1980: {
		"first": ["지", "민", "성", "재", "준", "승", "현", "상", "태", "정",
				  "동", "종", "경", "진", "우", "형", "규", "영", "창", "석"],
		"second": ["훈", "수", "우", "현", "원", "호", "석", "재", "민", "찬",
				   "진", "혁", "규", "빈", "환", "열", "택", "범", "성", "준"],
	},
	1990: {
		"first": ["지", "민", "준", "서", "현", "예", "우", "성", "재", "승",
				  "동", "건", "태", "진", "찬", "규", "정", "형", "상", "주"],
		"second": ["훈", "우", "현", "호", "성", "민", "재", "빈", "찬", "혁",
				   "석", "준", "원", "영", "수", "환", "규", "일", "범", "진"],
	},
	2000: {
		"first": ["서", "도", "하", "시", "지", "예", "주", "민", "건", "유",
				  "은", "재", "우", "현", "태", "선", "채", "연", "성", "준"],
		"second": ["준", "윤", "우", "민", "훈", "혁", "빈", "호", "현", "찬",
				   "율", "재", "성", "온", "결", "환", "겸", "안", "람", "진"],
	},
}

## 나이와 현재 연도로부터 이름을 만든다.
##
## rng   : 시드가 고정된 난수원 (GDD 1.2)
## age   : 회원 나이
## year  : 게임 내 현재 연도
##
## returns: {"surname": "김", "given": "영수", "full": "김영수"}
static func generate(rng: RandomNumberGenerator, age: int, year: int) -> Dictionary:
	var surname: String = _pick_weighted(rng, SURNAMES)
	var decade: int = _birth_decade(age, year)
	var pool: Dictionary = GIVEN_SYLLABLES[decade]
	var first: String = pool["first"][rng.randi() % pool["first"].size()]
	var second: String = pool["second"][rng.randi() % pool["second"].size()]
	# 같은 음절이 겹치면("진진", "규규") 어색하므로 다시 뽑는다.
	# 두 풀에 공통 음절이 있어 드물게 발생한다.
	var guard: int = 0
	while second == first and guard < 8:
		second = pool["second"][rng.randi() % pool["second"].size()]
		guard += 1
	var given: String = first + second
	return {"surname": surname, "given": given, "full": surname + given}


## 명단 전체를 한 번에 만들 때 쓴다. 동명이인을 피한다.
## 성씨 중복은 허용한다 — 김씨가 셋인 것이 오히려 현실적이고 별명의 근거가 된다.
static func generate_many(
	rng: RandomNumberGenerator, count: int, ages: Array[int], year: int
) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var used: Dictionary = {}
	for i in count:
		var age: int = ages[i] if i < ages.size() else 35
		var name: Dictionary = {}
		# 동명이인이 나오면 최대 20회까지 다시 뽑는다.
		for _attempt in 20:
			name = generate(rng, age, year)
			if not used.has(name["full"]):
				break
		used[name["full"]] = true
		out.append(name)
	return out


static func _birth_decade(age: int, year: int) -> int:
	var birth_year: int = year - age
	var decade: int = int(floor(birth_year / 10.0)) * 10
	# 풀이 없는 연대는 가장 가까운 쪽으로 붙인다.
	if decade < 1960:
		return 1960
	if decade > 2000:
		return 2000
	return decade


static func _pick_weighted(rng: RandomNumberGenerator, table: Array[Dictionary]) -> String:
	var total: int = 0
	for row in table:
		total += int(row["w"])
	var roll: int = rng.randi() % total
	for row in table:
		roll -= int(row["w"])
		if roll < 0:
			return str(row["n"])
	return str(table[0]["n"])

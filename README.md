# ProjectC

Godot 4.6.1 / GDScript 기반 2D 게임 프로젝트. 기획 및 개발 문서.

## 시작하기

### 필요한 것

- **Godot 4.6.1** (표준 빌드) — `C:\Users\user\Tools\Godot\godot.exe`
- **VSCode** + [godot-tools](https://marketplace.visualstudio.com/items?itemName=geequlim.godot-tools) 확장

둘 다 이미 구성돼 있다. 다른 PC 에서 세팅한다면 `.vscode/settings.json` 의
`godotTools.editorPath.godot4` 와 `tools/check-scripts.ps1` 의 `$Godot` 경로를 고칠 것.

### 작업 흐름

VSCode 에서 자동완성·정의 이동을 쓰려면 **Godot 에디터가 켜져 있어야 한다.**
LSP 서버가 에디터 안에서 돌기 때문이다 (127.0.0.1:6005).

1. Godot 에디터 실행 — `Ctrl+Shift+P` → `Tasks: Run Task` → **Godot: 에디터 열기**
2. 씬/노드 편집은 Godot 에서, 스크립트는 VSCode 에서
   - Godot 의 FileSystem 패널에서 `.gd` 를 더블클릭하면 VSCode 가 해당 줄로 열린다
3. 실행 — `F5` (브레이크포인트 사용 가능)

### VSCode 태스크

| 태스크 | 용도 |
| --- | --- |
| Godot: 에디터 열기 | 에디터 실행 + LSP 서버 제공 |
| Godot: 프로젝트 실행 (터미널 출력) | `print()` 출력을 터미널에서 바로 본다 |
| Godot: 전체 스크립트 검증 | 모든 `.gd` 파싱 검사 (커밋 전) |
| Godot: 현재 스크립트 문법 검사 | 열려 있는 파일만 검사 |
| Godot: 에셋 재임포트 | `.godot/` 캐시 재생성 |

### 디버그 구성 (F5)

| 구성 | 용도 |
| --- | --- |
| Godot: 프로젝트 실행 (디버그) | 기본 |
| Godot: 현재 씬만 실행 | 씬 단위 검증 |
| Godot: 실행 (콜리전 표시) | 물리 디버깅 |
| Godot: 실행 중인 게임에 attach | 에디터에서 실행한 게임에 붙기 |

### 커밋 전 확인

```powershell
./tools/check-scripts.ps1
```

`--import` 는 스크립트 파싱 에러를 잡지 못하므로 이 스크립트를 쓴다.
자세한 이유는 [docs/03-tech.md](docs/03-tech.md) 참고.

## 문서

| 문서 | 내용 |
| --- | --- |
| [docs/00-concept.md](docs/00-concept.md) | 게임 컨셉, 코어 루프 — **여기부터 채운다** |
| [docs/01-gdd.md](docs/01-gdd.md) | 게임 디자인 문서, 시스템·씬 구조 |
| [docs/02-scope.md](docs/02-scope.md) | 스코프, 마일스톤 |
| [docs/03-tech.md](docs/03-tech.md) | 기술 결정 기록, 알려진 함정 |

## 폴더 구조

```
scenes/          씬 (.tscn)
  levels/          레벨
  entities/        플레이어·적 등 재사용 오브젝트
  ui/              메뉴·HUD
scripts/         GDScript
  entities/
  systems/         전역 시스템·매니저
  ui/
resources/       커스텀 Resource (.tres)
assets/          원본 에셋
  sprites/ audio/ fonts/ ui/
tools/           개발용 스크립트 (게임에 포함되지 않음)
docs/            기획·기술 문서
```

## 입력 액션

`project.godot` 의 InputMap 에 등록된 기본 액션:

| 액션 | 키 |
| --- | --- |
| `move_left` / `move_right` / `move_up` / `move_down` | `A`/`D`/`W`/`S` + 방향키 |
| `interact` | `Space` |
| `pause` | `Esc` |

장르가 확정되면 [docs/01-gdd.md](docs/01-gdd.md) 에 맞춰 조정한다.

# 03. 기술 결정 기록

환경 구성 시점에 실제로 확인한 사실과, 그에 따라 내린 결정을 남긴다.
값을 바꿀 때 "왜 이렇게 돼 있었는지" 다시 파헤치지 않기 위한 문서다.

## 확정된 환경

| 항목 | 값 |
| --- | --- |
| 엔진 | Godot 4.6.1.stable.official (`14d19694e`) |
| 엔진 경로 | `C:\Users\user\Tools\Godot\godot.exe` (GUI) / `godot_console.exe` (CLI) |
| 스크립트 언어 | GDScript |
| 타겟 플랫폼 | PC (Steam) — 웹·모바일 계획 없음 |
| 렌더러 | `forward_plus` |
| VSCode 확장 | `geequlim.godot-tools` 2.7.1 |
| LSP 포트 | **6005** |
| DAP 포트 | **6006** |

## 결정 사항

### GDScript 선택

엔진과 밀착돼 있어 빌드 단계가 없고, 문서·튜토리얼 대부분이 GDScript 기준이다.
C# 은 Mono 빌드가 따로 필요하고 수정할 때마다 컴파일이 끼어든다.
`.NET` 라이브러리가 꼭 필요해지면 그때 재검토한다.

### 렌더러 = `forward_plus`

타겟이 **PC(Steam) 전용**으로 확정됐다. 웹·모바일 계획이 없다.

초기에는 `mobile` 을 골랐었다. 2D 에서 `forward_plus` 의 클러스터드 라이팅
오버헤드가 안 쓰인다는 이유였지만, 그 선택의 실질적 근거는 "모바일 이식 여지"였다.
그게 사라진 이상 데스크톱 GPU 에서 오버헤드는 무의미한 수준이고,
`forward_plus` 쪽이 기능 제약이 없다:

- 2D 라이팅·노멀맵·섀도우가 모두 온전히 동작
- 고급 셰이더 기능에 제한 없음 (`mobile` 은 일부 기능이 빠져 있어
  나중에 부딪히면 그때 렌더러를 바꿔야 한다)
- MSAA 등 안티에일리어싱 옵션 폭이 넓음

Godot 공식 권장도 데스크톱 타겟은 Forward+ 다.

- 위치: `project.godot` 의 `rendering/renderer/rendering_method`
- 함께 바꿔야 하는 것: `application/config/features` 의 `"Forward Plus"`

### 기본 해상도 1920x1080 + `canvas_items` 스트레치

`window/stretch/mode="canvas_items"` 는 UI 를 해상도에 맞춰 스케일한다.
실제 창은 `window_width_override`/`height_override` 로 1280x720 으로 뜬다.
`window/stretch/aspect` 는 기본값 `keep` 이라 파일에 안 보이지만 적용돼 있다.

#### 픽셀아트 확정 — 단, 해상도는 낮추지 않는다

**이전 판단을 정정한다.** 일반적인 픽셀아트 게임 조언은 "내부 해상도를 640x360 으로
낮추고 Nearest 필터" 다. 이 프로젝트에는 **틀린 조언이다.**

이유는 장르다. 이 게임은 텍스트·표·목록이 화면의 대부분을 차지하는 매니지먼트 게임이다.
회원 12명의 스탯 표, 이벤트 텍스트, 라인업 목록을 동시에 보여줘야 한다.

- 640x360 에서는 한글이 12~16px 이하로 내려가면 **판독이 불가능하다.**
  (한글은 라틴 문자보다 획이 많아 최소 픽셀 수가 크다)
- 그 해상도에서 표시 가능한 정보량으로는 매니지먼트 게임의 UI 가 성립하지 않는다

대신 **"픽셀아트 에셋 + 네이티브 해상도 UI"** 조합을 쓴다. 픽셀아트 전략/경영 게임이
보통 택하는 방식이다.

| 설정 | 값 | 이유 |
| --- | --- | --- |
| `viewport_width` / `height` | **1920 / 1080 유지** | 텍스트 밀도 확보 |
| `textures/canvas_textures/default_texture_filter` | **`0` (Nearest)** ✅ 적용됨 | 도트 스프라이트 선명도 |

- 회원 도트(8~16px)는 **정수배(4x, 6x, 8x)로만** 확대할 것. 정수배가 아니면
  Nearest 라도 픽셀이 불균등해진다
- UI 텍스트는 픽셀 폰트를 강제하지 않는다. 도트 스프라이트와 일반 폰트를 섞어도
  전혀 이상하지 않다
- **한글 픽셀 폰트는 선택지가 매우 적다.** 픽셀 폰트를 쓰기로 한다면 라이선스와
  글자 커버리지(한글 완성형 11,172자)를 반드시 먼저 확인할 것. 여기서 막히는 경우가 흔하다

`default_texture_filter=0` 은 전역 설정이라 나중에 비픽셀 에셋을 쓰면 계단이 생긴다.
그때는 해당 노드의 `texture_filter` 를 개별로 바꾸면 된다.

#### 종횡비

`window/stretch/aspect` 는 기본값 `keep` → 레터박스. 스팀덱(1280x800, 16:10)이나
울트라와이드에서 검은 띠가 생긴다. UI 중심 게임이므로 `expand` 가 더 나을 수 있다.
UI 레이아웃을 잡을 때 같이 결정할 것.

### LSP 포트를 6005 로 명시

Godot 4.6 의 LSP 기본 포트는 6005, DAP 는 6006 이다 (공식 문서 및 실측 확인).
그런데 **godot-tools 2.7.1 의 기본값은 6008** 이라 그냥 두면 연결에 실패한다.
그래서 `.vscode/settings.json` 에 `godotTools.lsp.serverPort: 6005` 를 명시했다.

### `--import` 는 스크립트 검증에 쓸 수 없음

실측 결과 `godot --headless --import` 는 GDScript 파싱 에러를 보고하지 않는다.
파일 단위 `--check-only --script <file>` 만 에러를 잡고, 종료 코드도 정확하다(에러 1 / 정상 0).
프로젝트 전체를 돌리는 CLI 명령이 없으므로 [`tools/check-scripts.ps1`](../tools/check-scripts.ps1) 로 파일을 순회한다.

### problemMatcher 직접 정의

godot-tools 2.7.1 은 problemMatcher 를 **제공하지 않는다**. `$godot` 같은 이름은 존재하지 않으며,
tasks.json 에서는 이름을 새로 정의할 수 없어 각 태스크에 객체로 인라인했다.
대상 포맷(컴파일·런타임 공통):

```
SCRIPT ERROR: Parse Error: Expected expression as the function argument.
   at: GDScript::reload (res://scripts/foo.gd:5)
```

## 미해결 / 나중에 할 것

### export templates 미설치

현재 `%APPDATA%\Godot\export_templates\` 가 비어 있다. 이게 없으면 실행 파일을
**뽑을 수 없다**. 개발 중에는 필요 없고, 처음 빌드할 때 설치하면 된다.

- 설치: Godot 에디터 → `Editor` → `Manage Export Templates` → `Download and Install`
- 4.6.1 버전이 정확히 맞아야 한다 (엔진 버전과 템플릿 버전 불일치 시 export 실패)
- 용량이 크다 (~1GB)

### Steam 관련

출시 준비 단계에서 다룰 것들. 지금 정할 필요는 없지만 미리 알아둘 것:

- **Steamworks 연동** (실적/클라우드 세이브)은 엔진 기본 기능이 아니다.
  GDScript 에서 쓰려면 [GodotSteam](https://godotsteam.com/) 같은 GDExtension 이 필요하다.
  실적을 넣을 계획이면 시스템 설계 단계에서 미리 고려할 것.
- **스팀덱**을 지원하려면 Linux export 도 준비하는 편이 낫다 (Proton 으로도 돌지만
  네이티브 쪽이 안정적). 해상도 1280x800(16:10) 대응은 위 스트레치 설정 참고.
- `export_presets.cfg` 는 `.gitignore` 에 들어가 있다. 서명 키·비밀번호가 들어갈 수
  있기 때문이다. 혼자 작업하는 동안은 문제없지만 백업은 따로 챙길 것.

## 알려진 함정

- **Godot 을 강제 종료하면 에디터 설정이 유실될 수 있다.** 반드시 창을 정상적으로 닫을 것.
  (에디터 설정은 종료 시점에 파일로 기록된다.)
- **`.ps1` 파일은 UTF-8 BOM 이 필요하다.** Windows PowerShell 5.1 은 BOM 없는 UTF-8 을
  ANSI 로 읽어서 한글이 깨진다. `tools/check-scripts.ps1` 은 BOM 포함으로 저장돼 있다.
- **에디터 설정에서 기본값과 같은 항목은 저장 시 자동으로 삭제된다.** 파일에 안 보인다고
  설정이 안 먹은 게 아니다.
- **GDScript 는 탭 인덴트다.** 스페이스가 섞이면 파싱 에러가 난다.
  `.vscode/settings.json` 에서 `editor.insertSpaces: false` 로 강제해 두었다.
- `godot.exe`(GUI 빌드)는 터미널로 stdout 을 보내지 않는다. 터미널 출력이 필요하면
  `godot_console.exe` 를 쓸 것.

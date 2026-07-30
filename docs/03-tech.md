# 03. 기술 결정 기록

환경 구성 시점에 실제로 확인한 사실과, 그에 따라 내린 결정을 남긴다.
값을 바꿀 때 "왜 이렇게 돼 있었는지" 다시 파헤치지 않기 위한 문서다.

## 확정된 환경

| 항목 | 값 |
| --- | --- |
| 엔진 | Godot 4.6.1.stable.official (`14d19694e`) |
| 엔진 경로 | `C:\Users\user\Tools\Godot\godot.exe` (GUI) / `godot_console.exe` (CLI) |
| 스크립트 언어 | GDScript |
| 렌더러 | `mobile` |
| VSCode 확장 | `geequlim.godot-tools` 2.7.1 |
| LSP 포트 | **6005** |
| DAP 포트 | **6006** |

## 결정 사항

### GDScript 선택

엔진과 밀착돼 있어 빌드 단계가 없고, 문서·튜토리얼 대부분이 GDScript 기준이다.
C# 은 Mono 빌드가 따로 필요하고 수정할 때마다 컴파일이 끼어든다.
`.NET` 라이브러리가 꼭 필요해지면 그때 재검토한다.

### 렌더러 = `mobile`

2D 게임에서 `forward_plus` 의 클러스터드 라이팅 오버헤드는 쓰이지 않는다.
`mobile` 은 Vulkan 기반이라 2D 기능은 거의 그대로 쓰면서 더 가볍고, 모바일 이식도 열려 있다.

- 웹(WebGL) 배포가 목표가 되면 `gl_compatibility` 로 바꿀 것
- 위치: `project.godot` 의 `rendering/renderer/rendering_method`

### 기본 해상도 1920x1080 + `canvas_items` 스트레치

`window/stretch/mode="canvas_items"` 는 UI 를 해상도에 맞춰 스케일한다.
실제 창은 `window_width_override`/`height_override` 로 1280x720 으로 뜬다.

- **픽셀아트로 간다면** 함께 바꿔야 하는 것:
  - 기본 해상도를 작게 (예: 640x360)
  - `rendering/textures/canvas_textures/default_texture_filter=0` (Nearest)
  - 이 두 개를 안 바꾸면 픽셀아트가 뭉개진다

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

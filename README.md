# Mi Band 10 Binary Dot Clock Lua

Mi Band 10용 Lua 엔진 워치페이스의 초기 소스입니다. 기본 화면은 검은 배경 위에 흰색 BCD 점만 가로로 배치해 현재 시각을 표현하고, 화면을 탭하면 날짜와 요일을 큰 고딕 계열 글자로 보여줍니다.

이 저장소는 기존 [mi-band-9-binary-dot-clock](https://github.com/kris-atelier/mi-band-9-binary-dot-clock)의 미니멀한 개념을 이어받되, Mi Band 10 Lua 워치페이스 구조에 맞춰 `app/lua/main.lua`에서 LVGL 객체를 직접 갱신하도록 다시 구성했습니다.

## 표시 규칙

```text
[AM/PM]   [시 4bit]   [분 6bit]
```

- 검은 배경, 흰색 켜짐 점, 매우 어두운 회색 꺼짐 점
- 숫자, 날짜, 날씨, 메시지, 걸음 수, 심박 수를 표시하지 않음
- 12시간제: 시는 `1–12`를 4bit로 표현
- 각 그룹은 왼쪽에서 오른쪽으로 LSB → MSB 순서
- AM/PM 점은 기본 활성화되어 있으며 `SHOW_AM_PM`으로 끌 수 있음
- 초는 별도 정보를 추가하지 않고 분 단위 갱신에 집중
- 화면을 탭하면 `YYYY.MM.DD` 날짜와 한국어 요일만 전체 화면으로 표시
- 날짜 화면에서 다시 탭하면 바이너리 클락으로 복귀

예를 들어 7시는 `0111`의 LSB-first 표시인 `1110`으로 보입니다.

## 프로젝트 구성

```text
app/lua/main.lua        # LVGL 점·날짜 화면과 dataman 시간 구독
src/watchface-config.json # 해상도·좌표·표시 규칙
src/preview.html        # 브라우저용 정적 미리보기
vendor/MiWatchLuaWatchfaces/ # m0tral Lua 워치페이스 예제 submodule
MiBand10BinaryDotClock.fprj # Lua 앱을 가리키는 Mi Create 프로젝트 초안
```

참고 예제를 함께 받으려면 다음처럼 submodule까지 초기화합니다.

```text
git clone --recurse-submodules https://github.com/kris-atelier/mi-band-10-binary-dot-clock-lua.git
```

이미 clone한 경우에는 다음 명령으로 가져옵니다.

```text
git submodule update --init --recursive
```

## 중요한 상태

이 저장소는 현재 **초기 개발본**입니다.

- m0tral의 [MiWatchLuaWatchfaces](https://github.com/m0tral/MiWatchLuaWatchfaces)와 [EasyFace](https://github.com/m0tral/EasyFace)를 참고한 구조입니다.
- EasyFace Gen2 Compiler v4.23의 `DeviceInfo.db`에서 일반 Mi Band 10은 `DeviceType=466`, 212×520, Lua 컨테이너 `Shape=34`로 확인했습니다. Mi Band 10 Pro(`567`)와 구분합니다.
- `app/lua/main.lua`의 2화면 동작은 유지합니다. 실제 M2459B1 / FW 3.2.8에서 Lua 실행과 화면 탭·한글 폰트는 아직 실기 검증이 필요합니다.
- 검증되지 않은 `.face` 바이너리는 저장소에 포함하지 않습니다.

## 개발 순서

1. Windows 환경에서 EasyFace 또는 호환 Mi Create 도구를 준비합니다.
2. [EasyFace v4.23 배포 파일](https://github.com/m0tral/EasyFace/releases/tag/v4.23)을 풀어 `Compiler.exe`와 `DeviceInfo.db`를 같은 디렉터리에 둡니다.
3. Windows에서 `python scripts/build_face.py --compiler C:\\path\\to\\Compiler.exe`를 실행합니다. macOS는 Wine이 설치된 경우 동일한 명령을 쓸 수 있습니다. 이 스크립트는 기존 Lua 파일을 변경하지 않고 프로젝트와 미리보기 이미지를 임시 디렉터리에 준비한 뒤 `dist/`에 `.face`와 동일 바이트의 `.bin`을 만듭니다.
4. `src/preview.html`과 실제 밴드에서 시간·탭 전환·글자 크기·점 간격을 확인합니다.
5. 출력 파일 헤더·해시·기기 정보를 확인하고 M2459B1 / FW 3.2.8의 워치페이스 설치 화면에서 명시적으로 확인한 뒤 시험합니다. 펌웨어 파일로 플래시하지 않습니다.

Windows 빌드 환경이 없다면 `band10-lua-build` 브랜치의 GitHub Actions가 같은 버전의 컴파일러를 해시 검증 후 받아 빌드를 시도하고 결과를 아티팩트로 남깁니다. Android 폰에 파일을 옮긴 것만으로 Mi Fitness 개발자 워치페이스에 자동 등록되지는 않습니다. 해당 앱의 실제 화면과 설치 대상 표시를 확인한 다음 수동 설치가 필요합니다.

이 프로젝트는 Xiaomi 공식 SDK나 공식 워치페이스 포맷 문서가 아닙니다. 기기·펌웨어·지역별 지원 차이를 확인한 뒤 사용하세요.

## 참고

- [m0tral/MiWatchLuaWatchfaces](https://github.com/m0tral/MiWatchLuaWatchfaces)
- [m0tral/EasyFace](https://github.com/m0tral/EasyFace)
- [kris-atelier/mi-band-9-binary-dot-clock](https://github.com/kris-atelier/mi-band-9-binary-dot-clock)
- [LVGL](https://lvgl.io/)

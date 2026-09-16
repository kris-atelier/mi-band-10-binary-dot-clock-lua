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
MiBand10BinaryDotClock.fprj # Lua 앱을 가리키는 Mi Create 프로젝트 초안
```

## 중요한 상태

이 저장소는 현재 **초기 개발본**입니다.

- m0tral의 [MiWatchLuaWatchfaces](https://github.com/m0tral/MiWatchLuaWatchfaces)와 [EasyFace](https://github.com/m0tral/EasyFace)를 참고한 구조입니다.
- 공개된 m0tral 예제에는 Mi Band 10 일반 모델의 확정 `DeviceType`/빌드 결과가 함께 제공되지 않습니다. 따라서 `.fprj`의 `DeviceType`은 `TODO` 주석이 있는 추정 placeholder입니다.
- 실제 Mi Band 10 펌웨어·EasyFace 버전에서 프로젝트를 열고, 대상 기기 식별자와 LVGL 원형 스타일을 확인한 뒤 `.face`를 빌드해야 합니다.
- 검증되지 않은 `.face` 바이너리는 저장소에 포함하지 않습니다.

## 개발 순서

1. Windows 환경에서 EasyFace 또는 호환 Mi Create 도구를 준비합니다.
2. `MiBand10BinaryDotClock.fprj`를 열고 Mi Band 10 일반 모델의 실제 대상 식별자로 교체합니다.
3. `app/lua/main.lua`를 Lua 앱 리소스로 패키징합니다.
4. `src/preview.html`과 실제 밴드에서 시간·탭 전환·글자 크기·점 간격을 확인합니다.
5. 자신의 펌웨어에서만 `.face`를 시험합니다.

이 프로젝트는 Xiaomi 공식 SDK나 공식 워치페이스 포맷 문서가 아닙니다. 기기·펌웨어·지역별 지원 차이를 확인한 뒤 사용하세요.

## 참고

- [m0tral/MiWatchLuaWatchfaces](https://github.com/m0tral/MiWatchLuaWatchfaces)
- [m0tral/EasyFace](https://github.com/m0tral/EasyFace)
- [kris-atelier/mi-band-9-binary-dot-clock](https://github.com/kris-atelier/mi-band-9-binary-dot-clock)
- [LVGL](https://lvgl.io/)

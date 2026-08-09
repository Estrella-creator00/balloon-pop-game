# POPPOP Project Status

> 이 문서는 POPPOP의 현재 코드 상태와 이미 확정된 방향을 정리한 작업 재개 기준 문서다.  
> 기준 브랜치: `source`

## 1. 프로젝트 개요

- Flutter Web 기반 풍선 터뜨리기 게임이다.
- 현재 개발 브랜치는 `source`다.
- GitHub Pages에 GitHub Actions 방식으로 배포한다.
- 모바일 웹, 특히 iPhone Safari 세로 화면을 우선 기준으로 개발한다.
- 향후 Android/iOS 앱 확장을 고려한다.
- 성능과 발열을 핵심 품질 항목으로 관리한다.
- 게임 루프는 약 30fps인 `33ms` 주기를 유지한다.

## 2. 현재 화면 번호

화면 식별자는 `lib/main.dart`의 `ScreenIds`에서 관리한다. 번호는 내부 개발 식별자이며 사용자 화면에는 표시하지 않는다.

| 번호 | 이름 | 현재 상태 |
|---|---|---|
| `ON-01` | 최초 닉네임 설정 | 온보딩 미완료 사용자에게 표시 |
| `H-01` | 홈 | 구현됨 |
| `S-01` | 상점 카테고리 | 식별자는 남아 있으나 현재 진입 흐름에서는 사용하지 않음 |
| `S-02` | 풍선 상점 상품 목록 | 구현됨. 홈에서 상점을 누르면 바로 진입 |
| `E-01` | 이벤트 | 하단 탭과 “이벤트 준비 중” 임시 화면만 구현 |
| `R-01` | 주간 랭킹 | Mock Data 기반 UI와 repository 경계 구현 |
| `C-01` | 코인 충전 | 홈 `+` 버튼, 4개 패키지 UI 구현. 실제 결제 미연동 |
| `SET-01` | 설정 메인 | 구현됨 |
| `SET-02` | 닉네임 변경 팝업 | 구현됨 |
| `SET-03` | 이용약관 | 임시 문구 화면 구현 |
| `SET-04` | 개인정보처리방침 | 임시 문구 화면 구현 |
| `SET-05` | 문의하기 | 임시 문구 화면 구현 |
| `SET-06` | 데이터 초기화 확인 팝업 | 구현됨 |
| `G-01` | 게임 플레이 | 구현됨 |
| `G-02` | 게임 완료 및 게임오버 | 구현됨 |

메인 탭 상태는 `MainTab.home`, `store`, `event`, `ranking`으로 구분한다. 홈의 랭킹 버튼은 현재 `WeeklyRankingPage`를 별도 route로 열고 뒤로가기로 원래 화면에 복귀한다.

### H-01 홈 UI

- 기록 보드는 `최고 기록`과 `최근 기록`을 한글로 표시하며 기존 저장 점수를 그대로 사용한다.
- Stage 카드는 얇은 반투명 외곽선과 기존의 약한 그림자를 사용하고 `추천!` 배지는 표시하지 않는다.
- 세 번째 구간 카드는 `21 ~ 30`으로 표시하고 `가짜 풍선을 터뜨리지 마세요!` 안내를 보여준다. 실제 gameplay 구현 범위는 현재 Stage 30까지다.
- 홈 Stage 페이지는 `ProgressStorage.nextPlayableStage()`가 속한 20개 Stage 단위 페이지를 초기 위치로 사용한다. 카드당 10개 Stage, 페이지당 카드 2개라는 계산을 사용하므로 향후 구간 추가 시 특정 Stage 예외 분기가 필요 없다.

## 3. 게임 기본 구조

게임 규칙은 주로 `lib/main.dart`의 `StageConfig`, `BalloonGamePage`에서 관리한다.

### 스테이지

- 현재 구현 범위는 Stage 1~30이다.
- Stage 1~9는 일반 풍선이며 스테이지 번호에 따라 2개에서 10개까지 1개씩 증가한다.
- Stage 10은 보스 1개다.
- Stage 11~19는 체력 2인 풍선이며 각 구간에서 다시 2개에서 10개까지 증가한다.
- Stage 20은 독립적으로 움직이는 보스 2개다.
- Stage 21~29는 1-hit 정상 풍선 2~10개와 Fake Balloon 2개가 함께 등장한다. 이 구간은 HP가 아니라 Fake 구별이 핵심 난이도다.
- Stage 21~29의 Fake Balloon 수는 스테이지와 무관하게 항상 정확히 2개다.
- Fake Balloon은 장착 중인 `BalloonSkinDefinition`, 공통 렌더러와 팔레트를 그대로 사용한다. 최종 출력은 opacity `0.35`를 우선 적용하고 채도와 밝기를 약간 낮춰, 어둡기보다 확실히 반투명하고 힘이 빠진 느낌으로 구분한다.
- Fake Balloon을 누르면 점수와 코인 없이 남은 시간이 2초 감소하며 `-2초` 피드백과 전용 실패 사운드가 재생된 후 제거된다.
- Stage 21~29는 정상 풍선이 모두 제거되는 즉시 클리어되며 남아 있는 Fake Balloon은 조용히 자동 제거된다.
- 새 풍선은 별도의 Fake 구현 없이 공통 `BalloonSkinRenderer`의 `isFake` 상태를 통해 자동 호환된다.
- 홈의 스테이지 페이지에서 `21 ~ 30` 카드로 Stage 21 구간을 직접 시작할 수 있으며 Stage 29 클리어 후 Stage 30 Boss로 연속 진행한다.
- Stage 30은 같은 크기와 이동 규칙을 쓰는 Boss Balloon 2개로 구성된다. 선명한 Real Boss 1개와 공통 opacity `0.35` 표현을 재사용하는 Fake Boss 1개가 공유 HP 12를 사용하며 HP Bar는 Real Boss에 하나만 표시한다.
- Stage 30 제한시간은 특수 Boss override로 18초다. Fake Boss를 누르면 공유 HP와 점수는 변하지 않고 남은 시간이 2초 감소하며, Real Boss를 맞힐 때마다 HP가 1 감소하고 `50%` 확률로 두 엔티티의 위치는 유지한 채 Real/Fake 역할만 교체한다.
- Stage 30의 두 Boss 사이에는 물리 충돌, 최소 거리, 위치 보정이 없다. 일부 또는 완전히 겹쳐도 각자의 위치·속도·방향 전환 주기를 유지한 채 자유롭게 통과하며, 초기 방향과 방향 전환 시점은 개체별로 다르게 시작한다. 겹친 터치 영역에서는 터치 지점과 중심이 더 가까운 Boss를 선택하고 정확히 같은 거리이면 안정적인 렌더 순서를 사용한다. 타격 가속은 유지하되 이동 속도는 최대 `220px/s`로 제한한다.
- Stage 30의 두 Boss는 모두 현재 장착 `BalloonSkinDefinition`과 공통 Boss 렌더러를 사용한다. 공유 HP가 0이 되면 둘을 함께 제거하고 공통 progression이 다음 구현 Stage의 존재 여부를 판단한다.
- 장기 Boss 설계는 Stage 번호에 따라 Boss 수만 계속 늘리지 않고, 각 10단위 Boss를 고유 패턴으로 차별화하는 것을 원칙으로 한다.
- 게임은 구현된 Stage 사이를 하나의 run으로 연속 진행한다. 일반 및 Boss Stage 모두 다음 Stage가 구현되어 있으면 공통 progression 규칙에 따라 `currentStage + 1`로 자동 진행하며 Boss Stage 자체는 run 종료 지점이 아니다.
- Stage 1에서 시작한 연속 플레이는 Stage 10→11과 Stage 20→21을 포함해 Stage 29까지 이어지며, 점수는 `_startGame()`을 다시 호출하지 않고 run 전체에서 누적된다.
- Stage 11 구간을 홈에서 직접 시작하면 해당 플레이 점수는 0부터 시작한다.

### HP, 속도 및 시간

`StageConfig.forStage()`의 현재 수치는 다음과 같다.

| 구간 | 풍선/보스 | HP | 제한 시간 |
|---|---|---:|---:|
| Stage 1~3 | 일반 풍선 2~4개 | 각 1 | 10초 |
| Stage 4~6 | 일반 풍선 5~7개 | 각 1 | 15초 |
| Stage 7~9 | 일반 풍선 8~10개 | 각 1 | 20초 |
| Stage 10 | 보스 1개 | 10 | 8초 |
| Stage 11~13 | 2회 터치 풍선 2~4개 | 각 2 | 12초 |
| Stage 14~16 | 2회 터치 풍선 5~7개 | 각 2 | 17초 |
| Stage 17~19 | 2회 터치 풍선 8~10개 | 각 2 | 22초 |
| Stage 20 | 보스 2개 | 각 15 | 10초 |
| Stage 21~23 | 정상 풍선 2~4개 + Fake 2개 | 모두 1-hit | 14초 |
| Stage 24~26 | 정상 풍선 5~7개 + Fake 2개 | 모두 1-hit | 19초 |
| Stage 27~29 | 정상 풍선 8~10개 + Fake 2개 | 모두 1-hit | 24초 |
| Stage 30 | Real Boss 1개 + Fake Boss 1개 | 공유 HP 12 | 18초 |

- 보스 기본 속도는 Stage 10에서 `105`, Stage 20에서 `126`이다.
- 보스는 타격할수록 현재 규칙에 따라 크기가 `0.965`배로 감소하고 속도가 `1.075`배로 증가한다.
- 일반 2회 터치 풍선은 첫 타격 시 제거되지 않고 크기가 `0.88`배로 줄어든다.

### 점수와 코인

- 일반 풍선을 개별적으로 터뜨릴 때는 점수가 없다.
- 일반 스테이지를 모두 클리어하면 남은 초만큼 점수를 얻는다.
- 보스는 완전히 제거되는 순간 보스 1개당 10점을 한 번만 얻는다.
- 보스 스테이지를 클리어하면 남은 초도 추가 점수로 더한다.
- 과거의 200/300/400 보너스는 사용하지 않는다.
- 게임 결과 확정 시 `CoinService.rewardForScore()`가 `score ~/ 10`으로 코인을 계산한다.
- `CoinRewardSession`이 한 플레이에서 결과 코인이 중복 지급되지 않게 한다.

### 성능 구조

- 게임 루프 주기: `gameLoopInterval = 33ms`.
- 실제 경과시간으로 `dt`를 계산하며 최대값은 `0.05초`다.
- 정적 하늘, 헤더, 풍선과 보스 렌더 영역은 `RepaintBoundary`로 분리한다.
- 파편과 폭발 링은 개별 위젯 대신 단일 `EffectsPainter`에서 일괄 렌더링한다.
- 게임 종료, 홈 이동, 일시정지 시 게임 루프와 관련 타이머를 정리한다.
- 홈의 움직이는 풍선은 게임 루프와 분리된 제한적인 애니메이션만 사용한다.
- Fake Balloon도 기존 30fps 이동 루프와 공통 풍선 위젯을 사용하며 별도 Timer나 AnimationController를 만들지 않는다.

## 4. 상점 구조

현재 진입 흐름은 다음과 같다.

```text
H-01 홈 → 상점 → S-02 풍선 상점
```

- 기존 카테고리형 S-01 상점 메인 화면은 현재 사용자 흐름에서 사용하지 않는다.
- 풍선 상점은 `일반`, `희귀`, `영웅`, `전설` 등급 섹션으로 구성한다. 내부 enum도 `heroic`을 사용하며 희귀도는 저장 키로 사용하지 않아 기존 구매·장착 ID에 영향이 없다.
- 등급 제목 아래 상품만 독립적인 가로 `ListView`로 스크롤한다. 모바일 swipe와 Web mouse/trackpad drag를 지원하며 상점 전체 세로 스크롤과 축을 분리한다.
- 상품 수는 하드코딩하지 않는다. `shopDefinitions`를 rarity별로 그룹화하므로 카탈로그에 상품을 추가하면 해당 등급 가로 목록에 자동으로 나타난다.
- 카드 폭은 고정해 좁은 모바일에서 약 2~3개가 보이며, 상품 수가 늘어나도 카드가 축소되지 않는다.
- 상단 필터는 `전체`, `보유`, `미보유`, `한정`이다.
- 실제 상품 카드를 누르면 직접 구매하지 않고 공통 풍선 미리보기 팝업을 연다.

상품 상태는 ID 기반으로 관리한다.

1. 미보유: 가격 표시, 구매 가능
2. 보유/미장착: `사용하기`
3. 현재 장착: `사용 중`

구매는 `lib/services/purchase_service.dart`의 `PurchaseService`, 코인은 `lib/services/coin_service.dart`의 `CoinService`가 담당한다. 장착 상품은 카테고리별로 하나만 유지한다.

## 5. 풍선 데이터 시스템

공통 모델과 registry는 `lib/balloon_skin_catalog.dart`에 있다.

- 모델: `BalloonSkinDefinition`
- registry: `BalloonSkinCatalog.definitions`
- 정렬된 상점 데이터: `BalloonSkinCatalog.shopDefinitions`
- 공통 렌더러: `lib/main.dart`의 `BalloonSkinRenderer`

`BalloonSkinDefinition`의 실제 필드는 다음과 같다.

- `id`
- `displayName`
- `description`
- `price`
- `rarity`
- `rendererType`
- `assetPath`
- `colorPalette`
- `popEffectType`
- `popSoundType`
- `idleAnimation`
- `specialBehavior`
- `visualVariantCount`
- `specialSpawnChance`
- `isDefault`
- `badge`
- `supportsBossSkin`
- `shopOrder`
- `previewColor`
- `avoidImmediateColorRepeat`
- `damageTint`
- `normalDamageTintStrength`
- `bossDamageTintStrength`
- `initiallyOwned`
- `background`

핵심 원칙은 다음과 같다.

```text
상점 카드 = 풍선 미리보기 = 일반 게임 풍선 = 보스 풍선
```

모두 같은 `BalloonSkinDefinition`과 `BalloonSkinRenderer`를 사용하며 위치와 크기만 각 화면에 맞게 달라진다. 게임의 위치, 속도, HP, 충돌과 탭 판정은 스킨 데이터와 분리한다.

새 풍선 추가 시 기본 절차는 다음과 같다.

1. 필요하면 최적화된 투명 에셋 한 장을 추가한다.
2. `BalloonSkinCatalog.definitions`에 정의 한 항목을 추가한다.
3. 새 연출이 필요하면 `BalloonPopEffectType`과 공통 효과 생성기에 연결한다.
4. 새 소리가 필요하면 `BalloonPopSoundType`과 공통 사운드 dispatch에 연결한다.
5. 전용 배경이 필요하면 `BalloonBackgroundRegistry`에 정적 배경을 등록한다.

## 6. 현재 풍선 상품

현재 `BalloonSkinCatalog`에는 출시 라인업 11개 정의가 있다.

### 기본 풍선 (`balloon-default`)

- 일반 등급, 가격 0
- 기본 보유 및 기본 장착 대상
- `BalloonRendererType.painted`로 기존 CustomPainter 렌더링 사용
- 기본 7색 팔레트
- 기본 파편 효과와 기본 팝 사운드
- 보스 스킨 지원
- 배경 `none`

### 하트 풍선 (`balloon-heart`)

- 일반 등급, 가격 100코인
- `assets/images/heart_balloon.png` 투명 에셋 사용
- 핑크, 레드, 바이올렛, 민트, 스카이블루, 옐로 6색 팔레트
- 같은 색의 즉시 연속 출현 방지
- 하트 조각 5개를 사용하는 일반 터짐 효과와 하트 전용 합성 사운드
- 일반 풍선과 Stage 10/20 보스 스킨 지원
- `NEW` 배지
- 배경 `none`

### 별 (`balloon-star`)

- 일반 등급, 가격 200코인
- 둥글고 통통한 5각 별 실루엣이며 광택을 실루엣 내부로 clip한다.
- 기본 파편 효과와 기본 팝 사운드 사용
- 초기 미보유, 보스 스킨 지원
- 배경 `none`

### 꽃 (`balloon-flower`)

- 일반 등급, 가격 200코인
- 통통한 다섯 꽃잎과 둥근 꽃 중심을 벡터로 렌더링한다.
- 기본 효과와 기본 사운드, 공통 색 variation을 사용한다.

### 모찌 (`balloon-rabbit`)

- 첫 희귀 등급 상품, 가격 500코인
- 기존 구매·장착 데이터 보존을 위해 `balloon-rabbit` ID를 유지한다.
- 둥근 머리와 긴 귀가 이어진 기존 토끼 실루엣을 유지하고 모든 하이라이트를 내부로 clip한다.
- 밝은 핑크·라벤더 중심 팔레트, 기본 파편 효과와 기본 팝 사운드 사용
- 초기 미보유, 보스 스킨 지원
- 배경 `none`

### 와리 / 킥스

- 와리(`balloon-wari`): 희귀, 600코인. 생성 시 반달·삼각 조각·둥근 단면 중 하나를 한 번 선택하며 수박 고유색을 유지한다.
- 킥스(`balloon-kicks`): 희귀, 700코인. 축구공 고유색을 유지하고 생성 시 1%로 결정된 개체만 공통 game loop phase로 회전한다.

### 부우 / 젤로

- 부우(`balloon-boo`): 영웅, 1000코인. 부드러운 다색 고스트, 꼬리 idle, 안개 pop, 고스트 합성음을 사용한다.
- 젤로(`balloon-jello`): 영웅, 1500코인. 다색 슬라임, 공통 phase squish와 벽 충돌 시 짧은 시각 압축, 젤 조각 pop, crackle 합성음을 사용한다.

### 루멘 / 슈슈

- 루멘(`balloon-lumen`): 전설, 5000코인. 보석색 수정, 은은한 내부광, 보스 피해 crack, 곡괭이·수정 파편 효과, crystal 합성음, `crystalCave` 배경을 사용한다.
- 슈슈(`balloon-chouchou`): 전설, 5000코인. 황금빛 슈와 크림, 은은한 breathe, 보스 피해 cream leak, 포크·크림 효과, cream 합성음, `creamCafe` 배경을 사용한다.

임시 상품 `balloon-a`, `balloon-b`는 카탈로그와 상점에서 제거된 상태다.

## 7. 풍선 미리보기 시스템

공통 팝업은 `lib/main.dart`의 `BalloonPreviewDialog`다.

- 실제 풍선 이름과 한국어 등급을 표시한다.
- 희귀 이상은 카탈로그의 한 줄 `description`과 실제 가격을 최대 2줄 범위로 표시한다.
- 큰 풍선은 게임과 같은 `BalloonSkinRenderer`로 렌더링한다.
- 상품의 실제 `colorPalette`를 순환하며 같은 색의 즉시 반복을 피한다.
- 풍선을 약 1초 표시한 뒤 실제 공통 효과와 효과음을 재생한다.
- 효과 재생 후 풍선을 다시 표시하고 반복한다.
- 미보유는 실제 가격의 구매 버튼, 보유는 `사용하기`, 장착은 비활성 `사용 중`을 표시한다.
- 구매와 장착은 기존 `PurchaseService`를 재사용하며 팝업과 뒤쪽 카드 상태가 함께 갱신된다.
- 미리보기에서는 점수, 코인 보상, 스테이지, HP, 게임 상태를 변경하지 않는다.
- 미리보기에서는 진동을 호출하지 않는다.
- 팝업을 닫으면 일회성 순환 `Timer`, 효과/idle `AnimationController`, 파편과 링을 정리한다.

새 풍선을 카탈로그에 등록하면 상품 카드가 해당 정의를 전달하므로 별도 Preview 위젯 없이 자동 연결된다.

## 8. 풍선 배경 시스템

선택형 전용 배경 구조는 `lib/balloon_background.dart`에 있다.

- 타입: `BalloonBackgroundType`
- 현재 타입 값에는 `none`, 기존 확장 타입, `crystalCave`, `creamCafe`가 있다.
- 정의: `BalloonBackgroundSpec`
- registry: `BalloonBackgroundRegistry`
- 공통 렌더러: `BalloonBackgroundRenderer`

`BalloonSkinDefinition.background`의 기본값은 `none`이다. 등급이 배경 유무를 자동으로 결정하지 않는다.

현재 상태:

- 기본 풍선 → `none`
- 하트 풍선 → `none`
- 루멘 → 정적 저비용 `crystalCave` gradient
- 슈슈 → 정적 저비용 `creamCafe` gradient
- 나머지 상품 → `none`

배경이 등록되면 동일한 `BalloonBackgroundRenderer`를 다음 두 곳에서 재사용하도록 설계되어 있다.

- G-01 게임 플레이 전체 배경
- `BalloonPreviewDialog` 중앙 미리보기 무대

`none`이거나 아직 에셋이 없는 타입은 기존 배경/흰 미리보기 fallback을 그대로 유지한다. 배경 renderer는 Timer나 AnimationController를 만들지 않는다.

## 9. 효과음 및 진동

### 효과음

- Web 구현: `lib/audio/pop_sound_web.dart`
- 비-Web/test 구현: `lib/audio/pop_sound_stub.dart`
- 공통 진입점: `PopSound`
- 설정 연결: `lib/services/settings_service.dart`
- 게임과 미리보기의 풍선별 dispatch: `lib/main.dart`의 `playBalloonPopSound()`

`BalloonPopSoundType`은 `basic`, `heart`, `ghost`, `crackle`, `crystal`, `cream`을 제공하며 Web Audio API로 짧게 합성한다. 설정의 효과음이 OFF면 `PopSound` 진입점에서 게임, 보스, 미리보기 소리를 모두 차단한다.

### 진동

- 서비스: `lib/services/haptic_service.dart`의 `HapticService`
- 실제 게임의 최종 풍선 터짐과 보스 타격에서 `shortImpact()`를 한 번 호출한다.
- 2회 터치 풍선의 첫 타격에는 진동하지 않는다.
- 상점 자동 미리보기에는 진동이 없다.
- 설정에서 ON/OFF할 수 있다.
- Web/플랫폼에서 지원하지 않거나 거부되면 예외를 조용히 무시해 게임을 계속한다.
- 서비스는 Timer, Ticker 또는 반복 작업을 소유하지 않는다.

## 10. 설정 페이지

설정 UI는 `lib/settings_page.dart`, 설정 상태는 `lib/services/settings_service.dart`에 있다.

SET-01 구성:

- 플레이어
  - 닉네임 → SET-02
- 게임 설정
  - 효과음
  - 진동
- 정보
  - 이용약관 → SET-03
  - 개인정보처리방침 → SET-04
  - 문의하기 → SET-05
- 하단
  - 버전 `1.0.0`
  - 데이터 초기화 → SET-06

SET-03, SET-04, SET-05는 화면과 이동 구조만 구현되어 있으며 정식 약관, 정책, 문의 채널 대신 향후 교체할 임시 안내 문구를 사용한다.

## 11. 닉네임 시스템

- 최초 설정 화면: `lib/onboarding_page.dart`의 `NicknameOnboardingPage` (`ON-01`)
- 변경 팝업: `lib/settings_page.dart`의 `NicknameEditDialog` (`SET-02`)
- 공통 검증/저장: `lib/services/settings_service.dart`의 `SettingsService`
- 저장 owner: `lib/storage/progress_storage_web.dart`의 `ProgressStorage`

규칙:

- 앞뒤 공백 제거
- 2자 이상 10자 이하
- 빈 값과 공백만 입력한 값은 저장 불가
- ON-01과 SET-02는 같은 `poppop_nickname` 값을 사용
- `poppop_nickname_onboarding_completed` 플래그가 없거나 `false`면 ON-01 표시
- ON-01 완료 후 플래그를 `true`로 저장하고 이후 바로 H-01 진입
- 기존 닉네임이 있으면 ON-01 입력창에 자동으로 채움
- 온보딩 플래그 추가는 다른 저장 키를 삭제하거나 재생성하지 않으므로 기존 사용자 데이터를 보존

향후 랭킹 서버에서 닉네임 중복 검사를 추가할 예정이다. 닉네임은 변경 가능한 표시 이름이므로 서버 사용자 식별자는 닉네임과 분리하는 것이 권장된다.

## 12. 코인 및 개발자 테스트 기능

- 코인은 `ProgressStorage`가 로컬 저장하고 `CoinService`가 조회·추가·점수 보상을 담당한다.
- 홈의 코인 캡슐 옆 `+` 버튼은 `lib/coin_purchase_page.dart`의 C-01 코인 충전 화면을 연다. C-01도 기존 `CoinService.balance`를 읽기만 한다.
- 코인 패키지는 `lib/coin/coin_package.dart`의 `CoinPackage`와 `coinPackages`에서 한 곳에 정의한다. 현재 UI 상품은 300/700/1,500/3,500 코인 4개다.
- 현재 결제 구현은 `lib/services/coin_purchase_service.dart`의 `DisabledCoinPurchaseService`이며 상품을 눌러도 코인을 지급하지 않고 준비 중 안내만 반환한다.
- 실제 결제 도입 시에는 `결제 요청 → 결제사 승인 → 서버 검증 → 중복 결제 확인 → 서버 코인 지급 → 최신 잔액 반영` 순서를 사용한다. 클라이언트가 결제 성공을 판단해 직접 로컬 코인을 추가하지 않는다.
- 게임 결과 점수 10점당 1코인을 지급하며 소수점은 버린다.
- 구매 성공 시 상품 가격만큼 즉시 차감한다.
- 홈과 상점은 같은 저장 잔액을 표시한다.
- 숨겨진 개발자 테스트 코인 기능이 `lib/dev/dev_coin_tool.dart`와 홈 상단 코인 터치 흐름에 존재한다.
- 7회 터치와 기존 인증을 매번 다시 수행하면 10,000코인을 반복 지급할 수 있다. 영구적인 1회 지급 플래그는 저장하지 않는다.
- 이 기능은 현재 브라우저/기기의 로컬 테스트 코인을 추가하기 위한 임시 개발 도구다.
- 실제 비밀번호는 이 문서에 기록하지 않는다.
- 출시 전 `TEMP DEV TOOL`, `DEV_COIN` 관련 코드를 검색해 제거 여부를 검토해야 한다.

## 13. 저장 데이터

Flutter Web에서는 브라우저 `window.localStorage`를 사용한다. 실제 키는 다음과 같다.

| 키 | 저장 내용 |
|---|---|
| `balloon_pop_game_second_section_unlocked` | Stage 11~20 구간 해금 여부 |
| `poppop_next_playable_stage` | 완료 기록에 따라 단조 증가하는 다음 플레이 가능 Stage. 홈 Stage 페이지 초기 위치 계산에 사용 |
| `poppop_best_score` | 최고 점수 |
| `poppop_last_score` | 직전 점수 |
| `poppop_coin_balance` | 보유 코인 |
| `poppop_owned_product_ids` | 구매한 상품 ID 집합 |
| `poppop_equipped_product_ids` | 카테고리별 장착 상품 ID |
| `poppop_nickname` | 공통 닉네임 |
| `poppop_nickname_onboarding_completed` | ON-01 완료 여부 |
| `poppop_sound_enabled` | 효과음 설정 |
| `poppop_haptic_enabled` | 진동 설정 |

`ProgressStorage.clear()`는 SET-06에서 사용자가 명시적으로 데이터 초기화를 확정했을 때 위 키를 모두 제거한다. 초기화 후 코인·점수·진행·구매·장착은 초기값, 효과음·진동은 기본 ON이 되고 닉네임과 온보딩 완료 플래그가 없어져 다음 앱 진입 시 ON-01이 다시 표시된다.

일반 업데이트, 새로고침 또는 배포 과정에서는 `clear()`를 호출하지 않는다.

## 14. Git / GitHub 배포 구조

워크플로 파일은 `.github/workflows/deploy-pages.yml`이다.

현재 배포 흐름:

```text
source push 또는 수동 workflow_dispatch
→ actions/checkout@v4
→ subosito/flutter-action@v2 (stable, cache)
→ flutter pub get
→ actions/configure-pages@v5
→ flutter build web --release --base-href "/balloon-pop-game/"
→ build/web/.nojekyll 생성
→ build/web/index.html을 build/web/404.html로 복사
→ actions/upload-pages-artifact@v4 (build/web)
→ actions/deploy-pages@v4
```

권한:

- `contents: read`
- `pages: write`
- `id-token: write`

배포 job은 `github-pages` environment와 배포 결과 `page_url`을 사용한다. concurrency group은 `github-pages`, `cancel-in-progress: false`다.

GitHub Pages의 Source는 **GitHub Actions**를 사용해야 하며, `github-pages` environment에서 `source` 브랜치의 deployment를 허용해야 한다. 과거처럼 빌드 결과를 `main` 브랜치에 commit/push하고 branch deployment를 기다리는 방식은 더 이상 사용하지 않는다.

## 15. 성능 원칙

다음 원칙을 유지한다.

- 30fps(`33ms`) 게임 루프와 실제 경과시간 기반 `dt`
- 긴 프레임의 `dt` 상한 `0.05초`
- 정적 배경, 헤더, 풍선과 보스의 `RepaintBoundary` 분리
- 파편과 링은 단일 `EffectsPainter` 중심으로 일괄 렌더링
- 파편별 Widget/Element/RenderObject 생성 금지
- 풍선별 AnimationController 남발 금지
- 반복 `Timer.periodic` 최소화와 화면 이탈 시 즉시 정리
- 동일 에셋을 상점, 미리보기, 일반 풍선, 보스에서 재사용
- 불필요한 대형 이미지와 패키지 추가 최소화
- Flutter Web, 특히 iPhone Safari 발열을 변경 검증 항목으로 유지

## 16. UI/디자인 원칙

- 밝고 둥글고 깔끔한 캐주얼 모바일 게임 UI를 유지한다.
- 모바일 세로 화면을 우선하며 SafeArea를 고려한다.
- 충분한 여백, 둥근 카드, 부드러운 그림자와 기존 포인트 컬러를 사용한다.
- 상점은 등급별 작은 가로 스크롤 카드, 미리보기는 큰 풍선 중심으로 대비한다.
- 설정 화면은 단순하고 읽기 쉽게 유지한다.
- 새 화면도 기존 색상, 폰트, radius, shadow와 컴포넌트 언어를 재사용한다.
- 요청 없이 임의의 새 디자인 시스템을 만들지 않는다.

## 17. 현재 확정된 상품 정책

풍선 상품은 다음을 하나의 데이터 세트로 묶는 방향이다.

```text
풍선 하나 구매
→ 모양/renderer
→ 색상 palette
→ 터짐 효과
→ 효과음
→ 필요할 경우 전용 배경
```

등급 방향:

- 일반: 기본적인 풍선 실루엣 변형. 기본·하트·별·꽃
- 희귀: 고유 이름과 성격, 특별한 실루엣. 모찌·와리·킥스
- 영웅: 고유 idle/effect/sound. 부우·젤로. 게임 배경은 바꾸지 않는다.
- 전설: 고유 animation/effect/sound와 데이터로 지정된 전용 배경. 루멘·슈슈
- 영웅: 구체적인 디자인 규칙은 아직 확정하지 않음
- 전설: 구체적인 디자인 규칙은 아직 확정하지 않음

등급이 배경을 강제하지 않는다. 실제 적용 여부는 각 `BalloonSkinDefinition.background` 데이터가 결정한다.

## 18. 이벤트 방향

- 홈 하단에 이벤트 탭이 존재한다.
- 현재는 `E-01`의 “이벤트 준비 중” 임시 화면과 선택 상태만 구현되어 있다.
- 시즌 이벤트는 일반 상점과 분리된 이벤트 영역에서 운영할 예정이다.
- 현재 데이터 구조는 향후 이벤트 배지와 이벤트 전용 풍선/테마 상품으로 확장할 수 있다.
- 실제 시즌, 보상, 일정, 서버 이벤트 데이터는 아직 구현하지 않았다.

## 19. 랭킹 방향

- 홈 하단에 랭킹 탭이 존재한다.
- 현재 `R-01`은 `lib/ranking/ranking_page.dart`의 `WeeklyRankingPage`로 구현되어 있다.
- 랭킹 주기는 매주 월요일 17:00 KST부터 다음 월요일 16:59:59 KST까지다.
- 현재 주 1~20위, 지난주 1위, 현재 1위와 내 순위를 표시한다.
- `RankingEntry`, `RankingWeek`, `RankingRepository` 경계를 사용하며 현재 데이터 공급자는 `MockRankingRepository`다.
- `weekId`는 KST 월요일 17:00 경계를 적용한 해당 월요일 날짜(`YYYY-MM-DD`)다.
- 현재 공통 닉네임이 TOP 20과 일치하면 목록 행을 강조하고, 목록 밖이면 별도 내 순위 카드를 표시한다.
- Loading, Empty, Error/재시도 UI가 준비되어 있다.
- 실시간 대전이 아니라 사용자별 해당 주 최고점 1개를 반영하는 주간 기록형 랭킹 정책이다.
- Supabase 연결, 실제 온라인 점수 저장, 과거 랭킹 조회, 서버 사용자 식별자와 닉네임 중복 검사는 아직 구현하지 않았다.

## 20. 아직 하지 않은 주요 기능

코드 기준 미구현 또는 임시 상태인 주요 항목:

- 실제 랭킹 서버와 오늘의 Top 10 데이터 동기화
- 닉네임 중복 검사와 닉네임과 분리된 서버 사용자 식별자
- 실제 이벤트 콘텐츠, 시즌 일정과 보상
- 추가 희귀 상품 및 첫 영웅·전설 등급 풍선 상품
- 실제 전용 배경 에셋과 registry 경로
- 실제 결제 및 코인 구매
- 정식 이용약관 본문
- 정식 개인정보처리방침 본문
- 실제 문의 채널
- 효과음/배경/음악 등 풍선 외 상품 카테고리의 최종 사용자 흐름
- Android/iOS 앱스토어 빌드와 배포
- 네이티브 앱별 진동/권한/오디오 동작 검증
- 출시 전 숨겨진 개발자 테스트 코인 기능 제거 여부 결정

이미 구현된 코인 획득, 로컬 구매·보유·장착, 풍선 미리보기, 하트 일반/보스 렌더링, 효과음·진동 설정은 미구현 목록에 포함하지 않는다.

## 21. 다음 작업 후보

현재 구조에서 자연스럽게 이어갈 수 있는 후보는 다음과 같다.

1. 정식 약관·개인정보처리방침·문의 채널 확정 및 SET-03~05 문구 교체
2. 서버 사용자 식별자와 랭킹 데이터 모델 설계
3. Supabase 기반 주간 Top 20 repository 구현과 R-01 데이터 공급자 교체
4. 추가 희귀 상품과 첫 영웅/전설 풍선을 `BalloonSkinCatalog` 방식으로 추가
5. 정적 전용 배경 에셋 하나를 `BalloonBackgroundRegistry`에 연결해 Preview/Game 공통 적용 검증
6. E-01 시즌 이벤트 데이터와 화면 구조 설계
7. 출시 전 개발자 테스트 도구와 개인정보/운영 체크리스트 검토
8. iPhone Safari 장시간 플레이 배터리·발열 회귀 측정

각 작업은 별도 요구사항이 확정된 뒤 진행하며 이 문서가 새 기능을 자동 승인하거나 확정하지는 않는다.

## 22. 새 작업 시 반드시 지킬 규칙

- 기존 UI를 요청 없이 크게 바꾸지 않는다.
- UI 작업 중 게임 규칙, 점수, 시간, 보스 난이도를 건드리지 않는다.
- 저장 키 변경 시 기존 사용자 데이터 호환과 마이그레이션을 먼저 고려한다.
- 전체 localStorage 초기화는 SET-06의 명시적 사용자 확인 외에는 사용하지 않는다.
- 새 풍선은 공통 `BalloonSkinDefinition`/`BalloonSkinCatalog` 구조를 사용한다.
- 풍선별 개별 `if`문을 여러 화면과 게임 로직에 반복하지 않는다.
- 상점 Preview, 일반 Game, Boss의 렌더링 일관성을 유지한다.
- 30fps, RepaintBoundary, 단일 EffectsPainter와 리소스 정리 구조를 유지한다.
- `.github/workflows/deploy-pages.yml`을 별도 배포 요청 없이 변경하지 않는다.
- 작업 후 반드시 다음을 실행한다.

```bash
dart format .
dart analyze lib test
flutter test
git diff --check
```

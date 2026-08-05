# 풍선 팡팡

Flutter Web으로 만든 30초 풍선 터뜨리기 게임입니다.

```bash
flutter pub get
flutter run -d chrome
```

## 화면 식별 기준

화면 번호는 개발 요청과 코드 검색을 위한 내부 식별자이며 실제 UI에는 표시하지 않습니다.

| 화면 번호 | 화면 이름 | 코드 연결 위치 |
| --- | --- | --- |
| H-01 | 홈 화면 | `_buildStartScreen()` |
| S-01 | 상점 카테고리 화면 | `_buildShopScreen()`, `_buildStoreCategoryGrid()` |
| S-02 | 상점 상품 목록 화면 | `_buildStoreCategoryDetail()` |
| E-01 | 이벤트 화면 | `_buildMainPlaceholder(MainTab.event)` |
| R-01 | 랭킹 화면 | `_buildMainPlaceholder(MainTab.ranking)` |
| SET-01 | 설정 화면 | `_onSettingsPressed()` 진입점 (현재 준비 중) |
| G-01 | 게임 플레이 화면 | `BalloonGamePage.build()` 플레이 분기 |
| G-02 | 게임 완료 및 게임오버 화면 | `_buildGameOver()` |
테스트

# TogeDog Camera

반려견 하네스에 부착된 카메라 단말을 가정한 Flutter 프로토타입입니다. 카메라 프레임에서 객체 탐지를 수행하고 보호자 앱과 연결되는 반려견 측 단말의 기술 가능성을 검증합니다.

## Stack

- Flutter / Dart
- `yolo_live_stream`
- `permission_handler`
- Android / iOS 카메라 권한

## Run

```bash
flutter pub get
flutter run
```

실제 카메라 기기에서 권한을 허용해야 합니다.

## Model Asset

대용량 모델은 공개 저장소에서 제외합니다. 승인된 모델 파일을 다음 위치에 배치한 후 앱 코드와 `pubspec.yaml`의 asset 설정을 확인합니다.

```text
assets/best_v3_float16.tflite
```

## Prototype Boundary

현재 저장소는 카메라·추론 흐름을 검증한 프로토타입입니다. 운영 환경에서는 네트워크 복원력, 배터리 최적화, 발열, 프레임 지연, 암호화 스트리밍과 기기 인증이 추가로 필요합니다.

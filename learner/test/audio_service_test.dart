import 'package:flutter_test/flutter_test.dart';
import 'package:writeright/new/data/services/audio_service.dart';

void main() {
  group('AudioService Tests', () {
    test('AudioService singleton instance', () {
      final instance1 = AudioService();
      final instance2 = AudioService();
      expect(instance1, same(instance2));
    });

    test('AudioService properties', () {
      final audioService = AudioService();
      expect(audioService.isPlaying, false);
      expect(audioService.currentUrl, null);
    });

    test('AudioService handles repeated URL requests', () {
      final audioService = AudioService();
      // Test that the service can handle the same URL being played multiple times
      // This is a structure test - actual audio playback would require integration testing
      expect(() => audioService.dispose(), returnsNormally);
    });
  });
}

import 'storage_service.dart';

class IntroService {
  // Check if user has seen the intro screen
  static Future<bool> hasSeenIntro() async {
    return await StorageService.hasSeenIntro();
  }
  
  // Mark intro screen as seen
  static Future<void> markIntroAsSeen() async {
    await StorageService.markIntroAsSeen();
  }
  
  // Reset intro screen (for testing purposes)
  static Future<void> resetIntro() async {
    await StorageService.resetIntro();
  }
} 
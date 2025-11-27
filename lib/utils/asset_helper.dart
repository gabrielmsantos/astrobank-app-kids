/// Helper class for consistent asset path handling across environments
class AssetHelper {
  /// Get the correct asset path for both development and production
  /// 
  /// In pubspec.yaml, assets are declared as: assets/images/
  /// 
  /// Usage:
  /// - AssetHelper.image('astrobank-logo-mini.png')
  ///   Returns: 'images/astrobank-logo-mini.png'
  /// 
  /// The full path to the file in pubspec.yaml would be: assets/images/astrobank-logo-mini.png
  /// But we reference it as: 'images/astrobank-logo-mini.png'
  /// 
  /// Flutter automatically prepends 'assets/' prefix
  static String image(String imageName) {
    return 'assets/images/$imageName';
  }

  /// Get all supported image paths
  static const Map<String, String> images = {
    'logo': 'assets/images/astrobank-logo-mini.png',
    'pig': 'assets/images/astrobank_pig.png',
    'background': 'assets/images/background.jpg',
    'background2': 'assets/images/background2.jpg',
    'background3': 'assets/images/background3.jpg',
  };

  /// Get image by key
  static String getImage(String key) {
    return images[key] ?? image(key);
  }
}


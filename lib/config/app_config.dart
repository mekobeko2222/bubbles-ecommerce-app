class AppConfig {
  // Cloudinary configuration
  static const String cloudinaryCloudName = 'bubblesdegla';
  static const String cloudinaryUploadPreset = 'bubbles';

  // Support contact information
  static const String supportPhoneNumber = '+201029231373';
  static const String whatsappPhoneNumber = '+201557929231';
  static const String whatsappPreFilledMessage = 'Hello Bubbles E-commerce support, I have a question about my order.';

  // Business hours configuration
  static const int businessStartHour = 12; // 12 PM
  static const int businessEndHour = 22; // 10 PM

  // App version
  static const String appVersion = '1.0.0';

  // Currency
  static const String currency = 'EGP';

  // Maximum images per product
  static const int maxImagesPerProduct = 5;

  // Order status options
  static const List<String> orderStatuses = [
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];

  // Payment methods
  static const Map<String, String> paymentMethodCodes = {
    'vodafoneCash': '*9*7*{amount}*01029231373#',
    'etisalatCash': '*777*01029231373*{amount}#',
    'weCash': '*500*01557929231*{amount}#',
  };

  // Instapay URL
  static const String instapayUrl = 'https://ipn.eg/S/dr.meko/instapay/1mG1BR';
}
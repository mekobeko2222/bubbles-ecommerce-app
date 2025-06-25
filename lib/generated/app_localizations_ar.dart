// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تطبيق فقاعات للتجارة الإلكترونية';

  @override
  String get homeScreenTitle => 'فقاعات للتجارة الإلكترونية';

  @override
  String get myBasketTitle => 'سلة المشتريات';

  @override
  String get checkoutTitle => 'الدفع';

  @override
  String get orderConfirmedTitle => 'تم تأكيد الطلب!';

  @override
  String get myOrdersTitle => 'طلباتي';

  @override
  String get userProfileTitle => 'ملف المستخدم';

  @override
  String get aboutUsTitle => 'من نحن';

  @override
  String get adminPanelTitle => 'لوحة تحكم المسؤول';

  @override
  String get continueShopping => 'متابعة التسوق';

  @override
  String get totalPrice => 'السعر الإجمالي';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String get shippingFee => 'رسوم الشحن';

  @override
  String get grandTotal => 'المجموع الكلي';

  @override
  String get placeOrder => 'إتمام الطلب';

  @override
  String get addToBasket => 'أضف إلى السلة';

  @override
  String get outOfStock => 'نفدت الكمية';

  @override
  String get relatedProducts => 'منتجات ذات صلة';

  @override
  String get description => 'الوصف';

  @override
  String get availability => 'التوفر';

  @override
  String inStock(Object quantity) {
    return 'متوفر ($quantity)';
  }

  @override
  String get quantity => 'الكمية';

  @override
  String pricePerItem(Object price) {
    return '$price جنيه مصري للقطعة';
  }

  @override
  String totalItemPrice(Object totalPrice) {
    return 'الإجمالي: $totalPrice جنيه مصري';
  }

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get displayName => 'اسم العرض';

  @override
  String get defaultShippingAddress => 'عنوان الشحن الافتراضي';

  @override
  String get shippingArea => 'منطقة الشحن';

  @override
  String get buildingNumber => 'رقم المبنى';

  @override
  String get floorNumber => 'رقم الطابق';

  @override
  String get apartmentNumber => 'رقم الشقة';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get loadingData => 'جاري تحميل البيانات...';

  @override
  String errorLoadingData(Object error) {
    return 'خطأ في تحميل البيانات: $error';
  }

  @override
  String get noDataFound => 'لا توجد بيانات.';

  @override
  String get productName => 'اسم المنتج';

  @override
  String get price => 'السعر';

  @override
  String get discount => 'الخصم (%)';

  @override
  String get quantityInStock => 'الكمية في المخزون';

  @override
  String get productDescription => 'وصف المنتج';

  @override
  String get tags => 'الكلمات الدلالية (مفصولة بفاصلة للمنتجات ذات الصلة)';

  @override
  String get addProductImages => 'أضف صور المنتج';

  @override
  String addMoreImages(Object current, Object max) {
    return 'أضف المزيد من الصور ($current/$max)';
  }

  @override
  String get selectCategory => 'اختر الفئة';

  @override
  String get addCategory => 'أضف فئة جديدة';

  @override
  String get categoryName => 'اسم الفئة';

  @override
  String get categoryIcon => 'أيقونة الفئة (رمز تعبيري)';

  @override
  String get addProduct => 'أضف منتج';

  @override
  String get manageProducts => 'إدارة المنتجات';

  @override
  String get manageAreas => 'إدارة المناطق';

  @override
  String get orders => 'الطلبات';

  @override
  String get analytics => 'التحليلات';

  @override
  String get addNewShippingArea => 'أضف منطقة شحن جديدة';

  @override
  String get areaName => 'اسم المنطقة';

  @override
  String get addArea => 'أضف منطقة';

  @override
  String get shippingFeeAmount => 'رسوم الشحن';

  @override
  String get totalOrders => 'إجمالي الطلبات';

  @override
  String get totalSales => 'إجمالي المبيعات';

  @override
  String get ordersByStatus => 'الطلبات حسب الحالة';

  @override
  String get orderId => 'معرف الطلب';

  @override
  String get userEmail => 'بريد المستخدم الإلكتروني';

  @override
  String get status => 'الحالة';

  @override
  String get orderDate => 'تاريخ الطلب';

  @override
  String get updateStatus => 'تحديث الحالة';

  @override
  String get reorder => 'إعادة الطلب';

  @override
  String get cancelOrder => 'إلغاء الطلب';

  @override
  String get loadingOrders => 'جاري تحميل طلباتك...';

  @override
  String get errorLoadingOrders => 'خطأ في تحميل الطلبات';

  @override
  String get noOrdersYet => 'لا توجد طلبات بعد';

  @override
  String get orderHistoryWillAppearHere => 'سجل طلباتك سيظهر هنا';

  @override
  String get cannotReorderEmptyList =>
      'لا يمكن إعادة طلب قائمة فارغة من العناصر.';

  @override
  String get addingItemsToBasket => 'جاري إضافة العناصر إلى السلة...';

  @override
  String uniqueItemsAddedToBasket(Object count) {
    return 'تمت إضافة $count عناصر فريدة إلى سلة المشتريات!';
  }

  @override
  String get view => 'عرض';

  @override
  String get searchProducts => 'البحث عن المنتجات...';

  @override
  String get searchResults => 'نتائج البحث';

  @override
  String get productsOnOffer => 'منتجات معروضة للبيع';

  @override
  String noProductsFound(Object query) {
    return 'لم يتم العثور على منتجات لـ \"$query\".';
  }

  @override
  String get noOffersFound => 'لا توجد عروض.';

  @override
  String get shopByCategory => 'تسوق حسب الفئة';

  @override
  String get unavailable => 'غير متاح';

  @override
  String get contactUs => 'اتصل بنا';

  @override
  String get ourMission => 'مهمتنا';

  @override
  String get whatWeOffer => 'ما نقدمه';

  @override
  String get secureCheckout => 'دفع آمن';

  @override
  String get realtimeOrderTracking => 'تتبع الطلبات في الوقت الفعلي';

  @override
  String get diverseProductCatalog => 'كتالوج منتجات متنوع';

  @override
  String get easyNavigation => 'سهولة التصفح';

  @override
  String get allRightsReserved =>
      '© 2024 فقاعات للتجارة الإلكترونية. جميع الحقوق محفوظة.';

  @override
  String get thankYouForYourOrder => 'شكراً لطلبك!';

  @override
  String get orderPlacedSuccessfully => 'تم تقديم طلبك بنجاح.';

  @override
  String get orderDetails => 'تفاصيل الطلب:';

  @override
  String get shippingAddress => 'عنوان الشحن:';

  @override
  String imageLoadingError(Object error, Object imageUrl, Object itemName) {
    return 'خطأ في تحميل الصورة لـ $itemName ($imageUrl): $error';
  }

  @override
  String get orderItemImageNotSupported => 'صورة عنصر الطلب غير مدعومة';

  @override
  String get orderCannotBeCancelled => 'لا يمكن إلغاء الطلب';

  @override
  String orderCurrently(Object status) {
    return 'هذا الطلب حاليًا \"$status\" ولا يمكن إلغاؤه من قبلك. يرجى الاتصال بدعم العملاء إذا كنت بحاجة إلى مزيد من المساعدة.';
  }

  @override
  String get confirmDeletion => 'تأكيد الحذف';

  @override
  String areYouSureDeleteProduct(Object productName) {
    return 'هل أنت متأكد أنك تريد حذف \"$productName\"؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get delete => 'حذف';

  @override
  String get cancel => 'إلغاء';

  @override
  String cloudinaryUploadFailed(Object statusCode) {
    return 'فشل تحميل Cloudinary: $statusCode. تحقق من وحدة تحكم Cloudinary.';
  }

  @override
  String failedToUploadImage(Object error) {
    return 'فشل تحميل الصورة: $error. تحقق من الإنترنت/بيانات الاعتماد.';
  }

  @override
  String get productAddedSuccessfully => 'تمت إضافة المنتج بنجاح!';

  @override
  String get enterValidNumbers =>
      'الرجاء إدخال أرقام صحيحة للسعر والخصم والكمية.';

  @override
  String failedToAddProduct(Object error) {
    return 'فشل إضافة المنتج: $error';
  }

  @override
  String get categoryNameCannotBeEmpty => 'لا يمكن أن يكون اسم الفئة فارغًا.';

  @override
  String get categoryIconCannotBeEmpty => 'لا يمكن أن تكون أيقونة الفئة فارغة.';

  @override
  String categoryAdded(Object categoryName) {
    return 'تمت إضافة الفئة \"$categoryName\"!';
  }

  @override
  String failedToAddCategory(Object error) {
    return 'فشل إضافة الفئة: $error';
  }

  @override
  String get noCategoriesAvailable => 'لا توجد فئات متاحة. يرجى إضافة بعض.';

  @override
  String get filterCategory => 'تصفية حسب الفئة';

  @override
  String get allCategories => 'جميع الفئات';

  @override
  String get noProductsFoundMatchingFilters =>
      'لم يتم العثور على منتجات مطابقة للمرشحات.';

  @override
  String areaAddedSuccessfully(Object areaName) {
    return 'تمت إضافة المنطقة \"$areaName\" بنجاح!';
  }

  @override
  String failedToAddArea(Object error) {
    return 'فشل إضافة المنطقة: $error';
  }

  @override
  String areaDeleted(Object areaName) {
    return 'تم حذف المنطقة \"$areaName\".';
  }

  @override
  String failedToDeleteArea(Object error) {
    return 'فشل حذف المنطقة: $error';
  }

  @override
  String get noShippingAreasFound =>
      'لم يتم العثور على مناطق شحن. أضف بعضها أعلاه.';

  @override
  String get updateOrderStatus => 'تحديث حالة الطلب';

  @override
  String get newStatus => 'الحالة الجديدة';

  @override
  String orderStatusUpdated(Object newStatus, Object orderId) {
    return 'تم تحديث حالة الطلب $orderId إلى \"$newStatus\"!';
  }

  @override
  String failedToUpdateOrderStatus(Object error) {
    return 'فشل تحديث حالة الطلب: $error';
  }

  @override
  String couldNotLaunchDialer(Object phoneNumber) {
    return 'تعذر تشغيل برنامج الاتصال لـ $phoneNumber. تأكد من تثبيت تطبيق الاتصال.';
  }

  @override
  String get phoneNumberNotAvailable => 'رقم الهاتف غير متاح.';

  @override
  String get noOrderDataAvailable => 'لا توجد بيانات طلب متاحة للتحليلات.';

  @override
  String get dashboardAnalytics => 'تحليلات لوحة التحكم';

  @override
  String get changePasswordComingSoon => 'وظيفة تغيير كلمة المرور (قريبًا)!';

  @override
  String get version => 'الإصدار';

  @override
  String get aboutUsContent =>
      'تطبيق فقاعات للتجارة الإلكترونية هو وجهتك الوحيدة للمنتجات عالية الجودة بأسعار معقولة. نحن ملتزمون بتقديم خدمة عملاء ممتازة وتجربة تسوق سلسة.';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get accessDenied => 'تم رفض الوصول';

  @override
  String get verifyingAdminAccess => 'جاري التحقق من صلاحيات المسؤول...';

  @override
  String get notAuthorizedToViewAdminPanel =>
      'أنت غير مصرح لك بمشاهدة لوحة تحكم المسؤول.';

  @override
  String get backToHome => 'العودة إلى الصفحة الرئيسية';

  @override
  String get addProductTabTitle => 'إضافة منتج';

  @override
  String get manageOfferCodesTitle => 'إدارة أكواد العروض';

  @override
  String get failedToLoadPreviousAddressDetails =>
      'فشل تحميل تفاصيل العنوان السابق';

  @override
  String get pleaseEnterPhoneNumber => 'يرجى إدخال رقم هاتفك';

  @override
  String get pleaseEnterValidEgyptianPhoneNumber =>
      'الرجاء إدخال رقم هاتف مصري صحيح';

  @override
  String pleaseEnterFieldName(String fieldName) {
    return 'الرجاء إدخال $fieldName';
  }

  @override
  String get pleaseSelectShippingArea => 'الرجاء اختيار منطقة الشحن';

  @override
  String get basketIsEmptyCanNotCheckout => 'السلة فارغة، لا يمكن الدفع';

  @override
  String get selectPaymentMethod => 'اختر طريقة الدفع';

  @override
  String get cashOnDelivery => 'الدفع عند الاستلام';

  @override
  String get vodafoneCash => 'فودافون كاش';

  @override
  String get etisalatCash => 'اتصالات كاش';

  @override
  String get weCash => 'وي كاش';

  @override
  String get instapay => 'إنستاباي';

  @override
  String get paymentInstruction => 'اختر طريقة الدفع المفضلة لديك';

  @override
  String get processingOrder => 'جاري معالجة الطلب';

  @override
  String get today => 'اليوم';

  @override
  String get tomorrow => 'غدًا';

  @override
  String get shippingInformation => 'معلومات الشحن';

  @override
  String get orderSummary => 'ملخص الطلب';

  @override
  String get estimatedDelivery => 'تاريخ التسليم المقدر';

  @override
  String get freeShipping => 'شحن مجاني';

  @override
  String get applyOfferCode => 'تطبيق رمز العرض';

  @override
  String offerCodeAddedSuccessfully(String code) {
    return 'تمت إضافة رمز العرض $code بنجاح';
  }

  @override
  String get basketIsEmpty => 'سلة المشتريات فارغة';

  @override
  String get addProductsToGetStarted => 'أضف بعض المنتجات للبدء';

  @override
  String get clearBasket => 'مسح السلة';

  @override
  String get clearBasketConfirmTitle => 'مسح السلة';

  @override
  String get clearBasketConfirmContent =>
      'هل أنت متأكد أنك تريد مسح سلة المشتريات الخاصة بك؟';

  @override
  String get clear => 'مسح';

  @override
  String get basketCleared => 'تم مسح السلة';

  @override
  String get removeProduct => 'إزالة المنتج';

  @override
  String get proceedToCheckout => 'المتابعة إلى الدفع';

  @override
  String get loadingProducts => 'جاري تحميل المنتجات...';

  @override
  String get errorLoadingProducts => 'خطأ في تحميل المنتجات';

  @override
  String get productsIn => 'منتجات في';

  @override
  String get checkBackLater => 'تحقق لاحقًا';

  @override
  String noProductsInCategory(String category) {
    return 'لا توجد منتجات في فئة $category';
  }

  @override
  String get confirmOrder => 'تأكيد الطلب';

  @override
  String orderTotal(String total) {
    return 'إجمالي الطلب: $total جنيه مصري';
  }

  @override
  String get deliveryTo => 'التوصيل إلى';

  @override
  String get areYouSureWantToPlaceOrder =>
      'هل أنت متأكد أنك تريد تقديم هذا الطلب؟';

  @override
  String get confirm => 'تأكيد';

  @override
  String get userNotLoggedInToPlaceOrder =>
      'المستخدم غير مسجل الدخول لتقديم الطلب';

  @override
  String productDoesNotExistInInventory(String name) {
    return 'المنتج $name غير موجود في المخزون';
  }

  @override
  String notEnoughStock(String name, int available, int requested) {
    return 'لا يوجد مخزون كافٍ لـ $name. المتاح: $available، المطلوب: $requested';
  }

  @override
  String failedToPlaceOrder(String error) {
    return 'فشل في تقديم الطلب: $error';
  }

  @override
  String couldNotLaunchUrl(String url) {
    return 'تعذر تشغيل الرابط: $url';
  }

  @override
  String paymentDialerPrompt(String code, String amount) {
    return 'اطلب $code لدفع $amount جنيه مصري';
  }

  @override
  String get ok => 'موافق';

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get itemsOrdered => 'العناصر المطلوبة';

  @override
  String get whatsAppUs => 'راسلنا واتساب';

  @override
  String get callUs => 'اتصل بنا';

  @override
  String get needAssistance => 'هل تحتاج مساعدة؟';

  @override
  String get supportTeamHelp => 'فريق الدعم لدينا هنا لمساعدتك';

  @override
  String get availableBusinessHours =>
      'متاح خلال ساعات العمل: 9 صباحًا - 6 مساءً';

  @override
  String failedToCancelOrder(String error) {
    return 'فشل إلغاء الطلب: $error';
  }

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String fieldNameMustBeNumber(String fieldName) {
    return '$fieldName يجب أن يكون رقمًا';
  }

  @override
  String errorLoadingCategories(String error) {
    return 'خطأ في تحميل الفئات: $error';
  }

  @override
  String get searchProductsToAdd => 'ابحث عن المنتجات لإضافتها';

  @override
  String get searchProductByName => 'ابحث عن المنتج بالاسم';

  @override
  String get selectedRelatedProducts => 'المنتجات ذات الصلة المختارة';

  @override
  String items(int count) {
    return '$count عناصر';
  }

  @override
  String get unnamedProduct => 'منتج بدون اسم';

  @override
  String get noOtherRelatedProductsFound =>
      'لم يتم العثور على منتجات أخرى ذات صلة';

  @override
  String get markAsOffer => 'ضع كعرض';

  @override
  String get pleaseLoginToViewOrders => 'الرجاء تسجيل الدخول لعرض طلباتك';

  @override
  String itemRemoved(String name) {
    return 'تمت إزالة العنصر $name';
  }

  @override
  String get basketEmptyCannotCheckout => 'السلة فارغة، لا يمكن الدفع';

  @override
  String yesterdayAt(String hour, String minute) {
    return 'أمس في $hour:$minute';
  }

  @override
  String todayAt(String hour, String minute) {
    return 'اليوم في $hour:$minute';
  }

  @override
  String get at => 'في';

  @override
  String get mon => 'الاثنين';

  @override
  String get tue => 'الثلاثاء';

  @override
  String get wed => 'الأربعاء';

  @override
  String get thu => 'الخميس';

  @override
  String get fri => 'الجمعة';

  @override
  String get sat => 'السبت';

  @override
  String get sun => 'الأحد';

  @override
  String itemCount(int count) {
    return '$count عناصر';
  }

  @override
  String get discountPercentage => 'نسبة الخصم';

  @override
  String get addOfferCode => 'إضافة رمز عرض';

  @override
  String get offerCodeRequired => 'رمز العرض مطلوب';

  @override
  String failedToAddOfferCode(String error) {
    return 'فشل إضافة رمز العرض: $error';
  }

  @override
  String offerCodeRemoved(String code) {
    return 'تمت إزالة رمز العرض $code';
  }

  @override
  String failedToRemoveOfferCode(String error) {
    return 'فشل إزالة رمز العرض: $error';
  }

  @override
  String get noOfferCodesFound => 'لم يتم العثور على رموز عروض';

  @override
  String get egyptianMobileNumberHint => 'رقم جوال مصري (11 رقمًا)';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get offerCode => 'رمز العرض';

  @override
  String get category => 'الفئة';

  @override
  String get offer => 'عرض';

  @override
  String get yes => 'نعم';

  @override
  String get no => 'لا';

  @override
  String get notAvailableAbbreviation => 'غير متاح';

  @override
  String get clearFilters => 'مسح المرشحات';

  @override
  String get noCategoriesAvailableForFiltering => 'لا توجد فئات متاحة للتصفية';

  @override
  String get noProductsFoundSimple => 'لم يتم العثور على منتجات';

  @override
  String productDeletedSuccessfully(String productName) {
    return 'تم حذف المنتج $productName بنجاح';
  }

  @override
  String failedToDeleteProduct(String error) {
    return 'فشل حذف المنتج: $error';
  }

  @override
  String areYouSureDeleteProductAdmin(String productName) {
    return 'هل أنت متأكد أنك تريد حذف \"$productName\"؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get editProduct => 'تعديل المنتج';

  @override
  String get pleaseSelectCategory => 'الرجاء اختيار فئة';

  @override
  String get productUpdatedSuccessfully => 'تم تحديث المنتج بنجاح';

  @override
  String failedToUpdateProduct(String error) {
    return 'فشل تحديث المنتج: $error';
  }

  @override
  String get priceAndQuantityCannotBeNegative =>
      'لا يمكن أن يكون السعر والكمية سالبة';

  @override
  String failedToSearchProducts(String error) {
    return 'فشل البحث عن المنتجات: $error';
  }

  @override
  String get noRelatedProductsFound => 'لم يتم العثور على منتجات ذات صلة';

  @override
  String get noShippingAreasAvailable => 'لا توجد مناطق شحن متاحة';

  @override
  String orderItems(int count) {
    return '$count عناصر مطلوبة';
  }

  @override
  String get filterByCategory => 'تصفية حسب الفئة';

  @override
  String get selectShippingArea => 'اختر منطقة الشحن';

  @override
  String get noProductsFoundGeneral => 'لم يتم العثور على منتجات';

  @override
  String get storeLocationTitle => 'موقع المتجر';

  @override
  String get nearbyShopsTitle => 'المتاجر القريبة';

  @override
  String get petAdoptionTitle => 'تبني الحيوانات الأليفة';

  @override
  String get findYourPerfectCompanion => 'اعثر على رفيقك المثالي';

  @override
  String get lovingPetsLookingForHomes => 'حيوانات أليفة محبة تبحث عن منازل';

  @override
  String get visitOurPhysicalStore => 'قم بزيارة متجرنا الفعلي';

  @override
  String get storeInformation => 'معلومات المتجر';

  @override
  String get address => 'العنوان';

  @override
  String get phone => 'الهاتف';

  @override
  String get operatingHours => 'ساعات العمل';

  @override
  String get findUsOnMap => 'اعثر علينا على الخريطة';

  @override
  String get interactiveMap => 'خريطة تفاعلية';

  @override
  String get clickButtonsBelowToOpen =>
      'انقر على الأزرار أدناه للفتح في خرائط جوجل';

  @override
  String get openInMaps => 'فتح في الخرائط';

  @override
  String get getDirections => 'احصل على الاتجاهات';

  @override
  String get callStore => 'اتصل بالمتجر';

  @override
  String get storeFeatures => 'مميزات المتجر';

  @override
  String get discoverLocalBusinesses => 'اكتشف الأعمال المحلية';

  @override
  String get supportYourLocalCommunity => 'ادعم مجتمعك المحلي';

  @override
  String get nearbyShopsUpdated => 'تم تحديث المتاجر القريبة';

  @override
  String get call => 'اتصال';

  @override
  String get browsePets => 'تصفح الحيوانات الأليفة';

  @override
  String get postAd => 'نشر إعلان';

  @override
  String get postPetForAdoption => 'نشر حيوان أليف للتبني';

  @override
  String get helpPetFindLovingHome => 'ساعد حيوان أليف في العثور على منزل محب';

  @override
  String get addPhotos => 'إضافة صور';

  @override
  String get petInformation => 'معلومات الحيوان الأليف';

  @override
  String get petName => 'اسم الحيوان الأليف';

  @override
  String get petType => 'نوع الحيوان الأليف';

  @override
  String get gender => 'الجنس';

  @override
  String get age => 'العمر';

  @override
  String get breed => 'السلالة';

  @override
  String get healthInformation => 'المعلومات الصحية';

  @override
  String get vaccinated => 'مطعم';

  @override
  String get spayedNeutered => 'معقم/مخصي';

  @override
  String get contactInformation => 'معلومات الاتصال';

  @override
  String get yourName => 'اسمك';

  @override
  String get yourPhoneNumber => 'رقم هاتفك';

  @override
  String get postPetForAdoptionButton => 'نشر حيوان أليف للتبني';

  @override
  String get posting => 'جاري النشر...';

  @override
  String get contact => 'اتصال';

  @override
  String get pleaseEnterPetName => 'يرجى إدخال اسم الحيوان الأليف';

  @override
  String get pleaseEnterAge => 'يرجى إدخال العمر';

  @override
  String get pleaseEnterDescription => 'يرجى إدخال الوصف';

  @override
  String get pleaseEnterYourName => 'يرجى إدخال اسمك';

  @override
  String get pleaseAddAtLeastOnePhoto => 'يرجى إضافة صورة واحدة على الأقل';

  @override
  String get petAdPostedSuccessfully => 'تم نشر إعلان الحيوان الأليف بنجاح!';

  @override
  String errorPostingAd(String error) {
    return 'خطأ في نشر الإعلان: $error';
  }

  @override
  String get noPetsAvailableForAdoption => 'لا توجد حيوانات أليفة متاحة للتبني';

  @override
  String get beFirstToPostPet => 'كن أول من ينشر حيوان أليف للتبني!';

  @override
  String get errorLoadingPets => 'خطأ في تحميل الحيوانات الأليفة';

  @override
  String get productDetails => 'تفاصيل المنتج';

  @override
  String get wishlistTitle => 'قائمة الأمنيات';

  @override
  String get supportSmallBusinessTitle => 'دعم الأعمال الصغيرة';

  @override
  String get manageNearbyShopsTitle => 'المتاجر القريبة';

  @override
  String get manageAppFeaturesTitle => 'ميزات التطبيق';

  @override
  String get appFeaturesManagement => 'إدارة ميزات التطبيق';

  @override
  String get controlWhichFeaturesVisible => 'تحكم في الميزات المرئية للعملاء';

  @override
  String get supportSmallBusinessScreen => 'شاشة دعم الأعمال الصغيرة';

  @override
  String get toggleVisibilityDescription =>
      'تبديل رؤية قسم دعم الأعمال الصغيرة في درج التطبيق للعملاء';

  @override
  String get featureIsEnabled => 'الميزة مُفعلة';

  @override
  String get featureIsDisabled => 'الميزة مُعطلة';

  @override
  String get customersCanSeeThisScreen =>
      'يمكن للعملاء رؤية هذه الشاشة في درج التطبيق';

  @override
  String get thisScreenIsHidden => 'هذه الشاشة مخفية عن العملاء';

  @override
  String get customizationOptions => 'خيارات التخصيص';

  @override
  String get menuTitle => 'عنوان القائمة';

  @override
  String get menuIcon => 'أيقونة القائمة';

  @override
  String get previewInAppDrawer => 'معاينة في درج التطبيق';

  @override
  String get saveFeatureSettings => 'حفظ إعدادات الميزة';

  @override
  String get saving => 'جاري الحفظ...';

  @override
  String get featureSettingsSavedSuccessfully => 'تم حفظ إعدادات الميزة بنجاح!';

  @override
  String get howItWorks => 'كيف يعمل';

  @override
  String get howItWorksDescription =>
      '• عند التفعيل، سيرى العملاء عنصر القائمة في درج التطبيق\n• عند التعطيل، يتم إخفاء عنصر القائمة تمامًا\n• التغييرات تسري على الفور لجميع المستخدمين\n• يمكنك تخصيص العنوان والأيقونة في أي وقت\n• استخدم تبويب \"المتاجر\" لإضافة أعمال إلى هذا القسم';

  @override
  String get addNewShop => 'إضافة متجر جديد';

  @override
  String get chooseDestinationAndAddDetails => 'اختر الوجهة وأضف تفاصيل المتجر';

  @override
  String get addToCollection => 'أضف إلى المجموعة:';

  @override
  String get shopImagesMultiple => 'صور المتجر * (يمكنك اختيار صور متعددة)';

  @override
  String get tapToSelectShopImages => 'اضغط لاختيار صور المتجر';

  @override
  String get youCanSelectMultipleImages => 'يمكنك اختيار صور متعددة';

  @override
  String get addMore => 'أضف المزيد';

  @override
  String get shopNameRequired => 'اسم المتجر *';

  @override
  String get pleaseEnterShopName => 'يرجى إدخال اسم المتجر';

  @override
  String get categoryRequired => 'الفئة *';

  @override
  String get categoriesForNearbyShops => 'فئات للمتاجر القريبة';

  @override
  String get categoriesForSmallBusinesses => 'فئات للأعمال الصغيرة';

  @override
  String get floor => 'الطابق';

  @override
  String get groundFloor => 'الطابق الأرضي';

  @override
  String get tellCustomersAboutShop => 'أخبر العملاء عن هذا المتجر...';

  @override
  String get tellCustomersAboutBusiness => 'أخبر العملاء عن هذا العمل...';

  @override
  String get addToNearbyShops => 'أضف إلى المتاجر القريبة';

  @override
  String get addToSupportSmallBusinesses => 'أضف إلى دعم الأعمال الصغيرة';

  @override
  String get adding => 'جاري الإضافة...';

  @override
  String get shopAddedSuccessfully => 'تمت إضافة المتجر بنجاح!';

  @override
  String get businessAddedSuccessfully => 'تمت إضافة العمل بنجاح!';

  @override
  String get pleaseSelectAtLeastOneImage =>
      'يرجى اختيار صورة واحدة على الأقل للمتجر';

  @override
  String get manageShops => 'إدارة المتاجر';

  @override
  String get editActivateOrRemoveShops =>
      'تعديل أو تفعيل أو إزالة المتاجر من المجموعات';

  @override
  String noShopsInCollectionYet(String collection) {
    return 'لا توجد متاجر في $collection بعد';
  }

  @override
  String get addYourFirstShop =>
      'أضف متجرك الأول باستخدام تبويب \"إضافة متجر\"!';

  @override
  String images(int count) {
    return '$count صور';
  }

  @override
  String floorLabel(String floor) {
    return 'الطابق: $floor';
  }

  @override
  String get active => 'نشط';

  @override
  String get inactive => 'غير نشط';

  @override
  String get activate => 'تفعيل';

  @override
  String get deactivate => 'إلغاء التفعيل';

  @override
  String get deleteShop => 'حذف المتجر';

  @override
  String areYouSureDeleteShop(String shopName) {
    return 'هل أنت متأكد أنك تريد حذف \"$shopName\"؟';
  }

  @override
  String get shopDeletedSuccessfully => 'تم حذف المتجر بنجاح';

  @override
  String get shopActivated => 'تم تفعيل المتجر';

  @override
  String get shopDeactivated => 'تم إلغاء تفعيل المتجر';

  @override
  String errorUpdatingShop(String error) {
    return 'خطأ في تحديث المتجر: $error';
  }

  @override
  String errorDeletingShop(String error) {
    return 'خطأ في حذف المتجر: $error';
  }

  @override
  String get errorLoadingShops => 'خطأ في تحميل المتاجر';

  @override
  String get couldNotLaunchPhoneDialer => 'تعذر تشغيل برنامج الاتصال';

  @override
  String errorLaunchingDialer(String error) {
    return 'خطأ في تشغيل برنامج الاتصال: $error';
  }

  @override
  String get supportLocalEntrepreneurs => 'ادعم رواد الأعمال المحليين';

  @override
  String get helpSmallBusinessesThrive =>
      'ساعد الأعمال الصغيرة على الازدهار في مجتمعك';

  @override
  String get loadingBusinesses => 'جاري تحميل الأعمال...';

  @override
  String get errorLoadingBusinesses => 'خطأ في تحميل الأعمال';

  @override
  String get noSmallBusinessesAvailable => 'لا توجد أعمال صغيرة متاحة';

  @override
  String get checkBackLaterForEntrepreneurs =>
      'تحقق لاحقًا من رواد الأعمال المحليين!';

  @override
  String get smallBusinessesUpdated => 'تم تحديث الأعمال الصغيرة';

  @override
  String get removedFromWishlist => 'تمت الإزالة من قائمة الأمنيات';

  @override
  String get addedToWishlist => 'تمت الإضافة إلى قائمة الأمنيات';

  @override
  String get handmade => 'الأعمال اليدوية';

  @override
  String get artAndCrafts => 'الفن والحرف';

  @override
  String get foodAndBeverage => 'الطعام والمشروبات';

  @override
  String get services => 'الخدمات';

  @override
  String get technology => 'التكنولوجيا';

  @override
  String get consulting => 'الاستشارات';

  @override
  String get retail => 'التجارة بالتجزئة';

  @override
  String get fitnessAndWellness => 'اللياقة والعافية';

  @override
  String get education => 'التعليم';

  @override
  String get other => 'أخرى';

  @override
  String get business => 'عمل';

  @override
  String get heart => 'قلب';

  @override
  String get handshake => 'مصافحة';

  @override
  String get support => 'دعم';

  @override
  String get volunteer => 'تطوع';

  @override
  String get group => 'مجموعة';

  @override
  String get store => 'متجر';

  @override
  String errorLoadingSettings(String error) {
    return 'خطأ في تحميل الإعدادات: $error';
  }

  @override
  String errorSavingSettings(String error) {
    return 'خطأ في حفظ الإعدادات: $error';
  }

  @override
  String get loadingFeatureSettings => 'جاري تحميل إعدادات الميزة...';

  @override
  String get failedToUploadImages => 'فشل تحميل الصور';

  @override
  String errorAddingShop(String error) {
    return 'خطأ في إضافة المتجر: $error';
  }

  @override
  String get nearbyShops => 'المتاجر القريبة';

  @override
  String get myWishlist => 'قائمة أمنياتي';

  @override
  String get petAdoption => 'تبني الحيوانات الأليفة';
}

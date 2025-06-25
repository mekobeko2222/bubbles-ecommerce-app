// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Bubbles E-commerce App';

  @override
  String get homeScreenTitle => 'Bubbles E-commerce';

  @override
  String get myBasketTitle => 'My Basket';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get orderConfirmedTitle => 'Order Confirmed!';

  @override
  String get myOrdersTitle => 'My Orders';

  @override
  String get userProfileTitle => 'User Profile';

  @override
  String get aboutUsTitle => 'About Us';

  @override
  String get adminPanelTitle => 'Admin Panel';

  @override
  String get continueShopping => 'Continue Shopping';

  @override
  String get totalPrice => 'Total Price';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get shippingFee => 'Shipping Fee';

  @override
  String get grandTotal => 'Grand Total';

  @override
  String get placeOrder => 'Place Order';

  @override
  String get addToBasket => 'Add to Basket';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String get relatedProducts => 'Related Products';

  @override
  String get description => 'Description';

  @override
  String get availability => 'Availability';

  @override
  String inStock(Object quantity) {
    return 'In Stock ($quantity)';
  }

  @override
  String get quantity => 'Quantity';

  @override
  String pricePerItem(Object price) {
    return 'EGP $price per item';
  }

  @override
  String totalItemPrice(Object totalPrice) {
    return 'Total: EGP $totalPrice';
  }

  @override
  String get email => 'Email';

  @override
  String get displayName => 'Display Name';

  @override
  String get defaultShippingAddress => 'Default Shipping Address';

  @override
  String get shippingArea => 'Shipping Area';

  @override
  String get buildingNumber => 'Building Number';

  @override
  String get floorNumber => 'Floor Number';

  @override
  String get apartmentNumber => 'Apartment Number';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get changePassword => 'Change Password';

  @override
  String get loadingData => 'Loading data...';

  @override
  String errorLoadingData(Object error) {
    return 'Error loading data: $error';
  }

  @override
  String get noDataFound => 'No data found.';

  @override
  String get productName => 'Product Name';

  @override
  String get price => 'Price';

  @override
  String get discount => 'Discount (%)';

  @override
  String get quantityInStock => 'Quantity in Stock';

  @override
  String get productDescription => 'Product Description';

  @override
  String get tags => 'Tags (comma-separated for related products)';

  @override
  String get addProductImages => 'Add Product Images';

  @override
  String addMoreImages(Object current, Object max) {
    return 'Add more images ($current/$max)';
  }

  @override
  String get selectCategory => 'Select Category';

  @override
  String get addCategory => 'Add New Category';

  @override
  String get categoryName => 'Category Name';

  @override
  String get categoryIcon => 'Category Icon (emoji)';

  @override
  String get addProduct => 'Add Product';

  @override
  String get manageProducts => 'Manage Products';

  @override
  String get manageAreas => 'Manage Areas';

  @override
  String get orders => 'Orders';

  @override
  String get analytics => 'Analytics';

  @override
  String get addNewShippingArea => 'Add New Shipping Area';

  @override
  String get areaName => 'Area Name';

  @override
  String get addArea => 'Add Area';

  @override
  String get shippingFeeAmount => 'Shipping Fee';

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get totalSales => 'Total Sales';

  @override
  String get ordersByStatus => 'Orders by Status';

  @override
  String get orderId => 'Order ID';

  @override
  String get userEmail => 'User Email';

  @override
  String get status => 'Status';

  @override
  String get orderDate => 'Order Date';

  @override
  String get updateStatus => 'Update Status';

  @override
  String get reorder => 'Reorder';

  @override
  String get cancelOrder => 'Cancel Order';

  @override
  String get loadingOrders => 'Loading your orders...';

  @override
  String get errorLoadingOrders => 'Error loading orders';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get orderHistoryWillAppearHere =>
      'Your order history will appear here';

  @override
  String get cannotReorderEmptyList => 'Cannot reorder empty list of items.';

  @override
  String get addingItemsToBasket => 'Adding items to basket...';

  @override
  String uniqueItemsAddedToBasket(Object count) {
    return '$count unique items added to your basket!';
  }

  @override
  String get view => 'View';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get searchResults => 'Search Results';

  @override
  String get productsOnOffer => 'Products on Offer';

  @override
  String noProductsFound(Object query) {
    return 'No products found for \"$query\".';
  }

  @override
  String get noOffersFound => 'No offers found.';

  @override
  String get shopByCategory => 'Shop by Category';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get ourMission => 'Our Mission';

  @override
  String get whatWeOffer => 'What We Offer';

  @override
  String get secureCheckout => 'Secure Checkout';

  @override
  String get realtimeOrderTracking => 'Real-time Order Tracking';

  @override
  String get diverseProductCatalog => 'Diverse Product Catalog';

  @override
  String get easyNavigation => 'Easy Navigation';

  @override
  String get allRightsReserved =>
      '© 2024 Bubbles E-commerce. All rights reserved.';

  @override
  String get thankYouForYourOrder => 'Thank you for your order!';

  @override
  String get orderPlacedSuccessfully =>
      'Your order has been placed successfully.';

  @override
  String get orderDetails => 'Order Details:';

  @override
  String get shippingAddress => 'Shipping Address:';

  @override
  String imageLoadingError(Object error, Object imageUrl, Object itemName) {
    return 'Error loading image for $itemName ($imageUrl): $error';
  }

  @override
  String get orderItemImageNotSupported => 'Order item image not supported';

  @override
  String get orderCannotBeCancelled => 'Order cannot be cancelled';

  @override
  String orderCurrently(Object status) {
    return 'This order is currently \"$status\" and cannot be cancelled by you. Please contact customer support if you need further assistance.';
  }

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String areYouSureDeleteProduct(Object productName) {
    return 'Are you sure you want to delete \"$productName\"? This action cannot be undone.';
  }

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String cloudinaryUploadFailed(Object statusCode) {
    return 'Cloudinary upload failed: $statusCode. Check Cloudinary Console.';
  }

  @override
  String failedToUploadImage(Object error) {
    return 'Failed to upload image: $error. Check internet/credentials.';
  }

  @override
  String get productAddedSuccessfully => 'Product added successfully!';

  @override
  String get enterValidNumbers =>
      'Please enter valid numbers for price, discount, and quantity.';

  @override
  String failedToAddProduct(Object error) {
    return 'Failed to add product: $error';
  }

  @override
  String get categoryNameCannotBeEmpty => 'Category name cannot be empty.';

  @override
  String get categoryIconCannotBeEmpty => 'Category icon cannot be empty.';

  @override
  String categoryAdded(Object categoryName) {
    return 'Category \"$categoryName\" added!';
  }

  @override
  String failedToAddCategory(Object error) {
    return 'Failed to add category: $error';
  }

  @override
  String get noCategoriesAvailable =>
      'No categories available. Please add some.';

  @override
  String get filterCategory => 'Filter by Category';

  @override
  String get allCategories => 'All Categories';

  @override
  String get noProductsFoundMatchingFilters =>
      'No products found matching filters.';

  @override
  String areaAddedSuccessfully(Object areaName) {
    return 'Area \"$areaName\" added successfully!';
  }

  @override
  String failedToAddArea(Object error) {
    return 'Failed to add area: $error';
  }

  @override
  String areaDeleted(Object areaName) {
    return 'Area \"$areaName\" deleted.';
  }

  @override
  String failedToDeleteArea(Object error) {
    return 'Failed to delete area: $error';
  }

  @override
  String get noShippingAreasFound => 'No shipping areas found. Add some above.';

  @override
  String get updateOrderStatus => 'Update Order Status';

  @override
  String get newStatus => 'New Status';

  @override
  String orderStatusUpdated(Object newStatus, Object orderId) {
    return 'Order $orderId status updated to \"$newStatus\"!';
  }

  @override
  String failedToUpdateOrderStatus(Object error) {
    return 'Failed to update order status: $error';
  }

  @override
  String couldNotLaunchDialer(Object phoneNumber) {
    return 'Could not launch dialer for $phoneNumber. Make sure a dialer app is installed.';
  }

  @override
  String get phoneNumberNotAvailable => 'Phone number not available.';

  @override
  String get noOrderDataAvailable => 'No order data available for analytics.';

  @override
  String get dashboardAnalytics => 'Dashboard Analytics';

  @override
  String get changePasswordComingSoon =>
      'Change Password functionality (coming soon)!';

  @override
  String get version => 'Version';

  @override
  String get aboutUsContent =>
      'Bubbles E-commerce is your one-stop shop for quality products at affordable prices. We are committed to providing excellent customer service and a seamless shopping experience.';

  @override
  String get logout => 'Logout';

  @override
  String get accessDenied => 'Access Denied';

  @override
  String get verifyingAdminAccess => 'Verifying admin access...';

  @override
  String get notAuthorizedToViewAdminPanel =>
      'You are not authorized to view the admin panel.';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get addProductTabTitle => 'Add Product';

  @override
  String get manageOfferCodesTitle => 'Manage Offer Codes';

  @override
  String get failedToLoadPreviousAddressDetails =>
      'Failed to load previous address details';

  @override
  String get pleaseEnterPhoneNumber => 'Please enter your phone number';

  @override
  String get pleaseEnterValidEgyptianPhoneNumber =>
      'Please enter a valid Egyptian phone number';

  @override
  String pleaseEnterFieldName(String fieldName) {
    return 'Please enter $fieldName';
  }

  @override
  String get pleaseSelectShippingArea => 'Please select shipping area';

  @override
  String get basketIsEmptyCanNotCheckout => 'Basket is empty, cannot checkout';

  @override
  String get selectPaymentMethod => 'Select Payment Method';

  @override
  String get cashOnDelivery => 'Cash on Delivery';

  @override
  String get vodafoneCash => 'Vodafone Cash';

  @override
  String get etisalatCash => 'Etisalat Cash';

  @override
  String get weCash => 'We Cash';

  @override
  String get instapay => 'Instapay';

  @override
  String get paymentInstruction => 'Choose your preferred payment method';

  @override
  String get processingOrder => 'Processing Order';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get shippingInformation => 'Shipping Information';

  @override
  String get orderSummary => 'Order Summary';

  @override
  String get estimatedDelivery => 'Estimated Delivery';

  @override
  String get freeShipping => 'Free Shipping';

  @override
  String get applyOfferCode => 'Apply Offer Code';

  @override
  String offerCodeAddedSuccessfully(String code) {
    return 'Offer code $code added successfully';
  }

  @override
  String get basketIsEmpty => 'Your basket is empty';

  @override
  String get addProductsToGetStarted => 'Add some products to get started';

  @override
  String get clearBasket => 'Clear Basket';

  @override
  String get clearBasketConfirmTitle => 'Clear Basket';

  @override
  String get clearBasketConfirmContent =>
      'Are you sure you want to clear your basket?';

  @override
  String get clear => 'Clear';

  @override
  String get basketCleared => 'Basket cleared';

  @override
  String get removeProduct => 'Remove Product';

  @override
  String get proceedToCheckout => 'Proceed to Checkout';

  @override
  String get loadingProducts => 'Loading products...';

  @override
  String get errorLoadingProducts => 'Error loading products';

  @override
  String get productsIn => 'Products in';

  @override
  String get checkBackLater => 'Check back later';

  @override
  String noProductsInCategory(String category) {
    return 'No products found in $category';
  }

  @override
  String get confirmOrder => 'Confirm Order';

  @override
  String orderTotal(String total) {
    return 'Order Total: EGP $total';
  }

  @override
  String get deliveryTo => 'Delivery to';

  @override
  String get areYouSureWantToPlaceOrder =>
      'Are you sure you want to place this order?';

  @override
  String get confirm => 'Confirm';

  @override
  String get userNotLoggedInToPlaceOrder => 'User not logged in to place order';

  @override
  String productDoesNotExistInInventory(String name) {
    return 'Product $name does not exist in inventory';
  }

  @override
  String notEnoughStock(String name, int available, int requested) {
    return 'Not enough stock for $name. Available: $available, Requested: $requested';
  }

  @override
  String failedToPlaceOrder(String error) {
    return 'Failed to place order: $error';
  }

  @override
  String couldNotLaunchUrl(String url) {
    return 'Could not launch URL: $url';
  }

  @override
  String paymentDialerPrompt(String code, String amount) {
    return 'Dial $code to pay EGP $amount';
  }

  @override
  String get ok => 'OK';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get itemsOrdered => 'Items Ordered';

  @override
  String get whatsAppUs => 'WhatsApp Us';

  @override
  String get callUs => 'Call Us';

  @override
  String get needAssistance => 'Need Assistance?';

  @override
  String get supportTeamHelp => 'Our support team is here to help you';

  @override
  String get availableBusinessHours =>
      'Available during business hours: 9 AM - 6 PM';

  @override
  String failedToCancelOrder(String error) {
    return 'Failed to cancel order: $error';
  }

  @override
  String get editProfile => 'Edit Profile';

  @override
  String fieldNameMustBeNumber(String fieldName) {
    return '$fieldName must be a number';
  }

  @override
  String errorLoadingCategories(String error) {
    return 'Error loading categories: $error';
  }

  @override
  String get searchProductsToAdd => 'Search products to add';

  @override
  String get searchProductByName => 'Search product by name';

  @override
  String get selectedRelatedProducts => 'Selected Related Products';

  @override
  String items(int count) {
    return '$count items';
  }

  @override
  String get unnamedProduct => 'Unnamed Product';

  @override
  String get noOtherRelatedProductsFound => 'No other related products found';

  @override
  String get markAsOffer => 'Mark as Offer';

  @override
  String get pleaseLoginToViewOrders => 'Please login to view your orders';

  @override
  String itemRemoved(String name) {
    return 'Item $name removed';
  }

  @override
  String get basketEmptyCannotCheckout => 'Basket is empty, cannot checkout';

  @override
  String yesterdayAt(String hour, String minute) {
    return 'Yesterday at $hour:$minute';
  }

  @override
  String todayAt(String hour, String minute) {
    return 'Today at $hour:$minute';
  }

  @override
  String get at => 'at';

  @override
  String get mon => 'Mon';

  @override
  String get tue => 'Tue';

  @override
  String get wed => 'Wed';

  @override
  String get thu => 'Thu';

  @override
  String get fri => 'Fri';

  @override
  String get sat => 'Sat';

  @override
  String get sun => 'Sun';

  @override
  String itemCount(int count) {
    return '$count items';
  }

  @override
  String get discountPercentage => 'Discount Percentage';

  @override
  String get addOfferCode => 'Add Offer Code';

  @override
  String get offerCodeRequired => 'Offer code is required';

  @override
  String failedToAddOfferCode(String error) {
    return 'Failed to add offer code: $error';
  }

  @override
  String offerCodeRemoved(String code) {
    return 'Offer code $code removed';
  }

  @override
  String failedToRemoveOfferCode(String error) {
    return 'Failed to remove offer code: $error';
  }

  @override
  String get noOfferCodesFound => 'No offer codes found';

  @override
  String get egyptianMobileNumberHint => 'Egyptian mobile number (11 digits)';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get offerCode => 'Offer Code';

  @override
  String get category => 'Category';

  @override
  String get offer => 'Offer';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get notAvailableAbbreviation => 'N/A';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get noCategoriesAvailableForFiltering =>
      'No categories available for filtering';

  @override
  String get noProductsFoundSimple => 'No products found';

  @override
  String productDeletedSuccessfully(String productName) {
    return 'Product $productName deleted successfully';
  }

  @override
  String failedToDeleteProduct(String error) {
    return 'Failed to delete product: $error';
  }

  @override
  String areYouSureDeleteProductAdmin(String productName) {
    return 'Are you sure you want to delete \"$productName\"? This action cannot be undone.';
  }

  @override
  String get editProduct => 'Edit Product';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get productUpdatedSuccessfully => 'Product updated successfully';

  @override
  String failedToUpdateProduct(String error) {
    return 'Failed to update product: $error';
  }

  @override
  String get priceAndQuantityCannotBeNegative =>
      'Price and quantity cannot be negative';

  @override
  String failedToSearchProducts(String error) {
    return 'Failed to search products: $error';
  }

  @override
  String get noRelatedProductsFound => 'No related products found';

  @override
  String get noShippingAreasAvailable => 'No shipping areas available';

  @override
  String orderItems(int count) {
    return '$count items ordered';
  }

  @override
  String get filterByCategory => 'Filter by Category';

  @override
  String get selectShippingArea => 'Select Shipping Area';

  @override
  String get noProductsFoundGeneral => 'No products found';

  @override
  String get storeLocationTitle => 'Store Location';

  @override
  String get nearbyShopsTitle => 'Nearby Shops';

  @override
  String get petAdoptionTitle => 'Pet Adoption';

  @override
  String get findYourPerfectCompanion => 'Find Your Perfect Companion';

  @override
  String get lovingPetsLookingForHomes => 'Loving pets looking for homes';

  @override
  String get visitOurPhysicalStore => 'Visit Our Physical Store';

  @override
  String get storeInformation => 'Store Information';

  @override
  String get address => 'Address';

  @override
  String get phone => 'Phone';

  @override
  String get operatingHours => 'Operating Hours';

  @override
  String get findUsOnMap => 'Find Us on Map';

  @override
  String get interactiveMap => 'Interactive Map';

  @override
  String get clickButtonsBelowToOpen =>
      'Click buttons below to open in Google Maps';

  @override
  String get openInMaps => 'Open in Maps';

  @override
  String get getDirections => 'Get Directions';

  @override
  String get callStore => 'Call Store';

  @override
  String get storeFeatures => 'Store Features';

  @override
  String get discoverLocalBusinesses => 'Discover Local Businesses';

  @override
  String get supportYourLocalCommunity => 'Support your local community';

  @override
  String get nearbyShopsUpdated => 'Nearby shops updated';

  @override
  String get call => 'Call';

  @override
  String get browsePets => 'Browse Pets';

  @override
  String get postAd => 'Post Ad';

  @override
  String get postPetForAdoption => 'Post Pet for Adoption';

  @override
  String get helpPetFindLovingHome => 'Help a pet find a loving home';

  @override
  String get addPhotos => 'Add Photos';

  @override
  String get petInformation => 'Pet Information';

  @override
  String get petName => 'Pet Name';

  @override
  String get petType => 'Pet Type';

  @override
  String get gender => 'Gender';

  @override
  String get age => 'Age';

  @override
  String get breed => 'Breed';

  @override
  String get healthInformation => 'Health Information';

  @override
  String get vaccinated => 'Vaccinated';

  @override
  String get spayedNeutered => 'Spayed/Neutered';

  @override
  String get contactInformation => 'Contact Information';

  @override
  String get yourName => 'Your Name';

  @override
  String get yourPhoneNumber => 'Your Phone Number';

  @override
  String get postPetForAdoptionButton => 'Post Pet for Adoption';

  @override
  String get posting => 'Posting...';

  @override
  String get contact => 'Contact';

  @override
  String get pleaseEnterPetName => 'Please enter pet name';

  @override
  String get pleaseEnterAge => 'Please enter age';

  @override
  String get pleaseEnterDescription => 'Please enter description';

  @override
  String get pleaseEnterYourName => 'Please enter your name';

  @override
  String get pleaseAddAtLeastOnePhoto => 'Please add at least one photo';

  @override
  String get petAdPostedSuccessfully => 'Pet ad posted successfully!';

  @override
  String errorPostingAd(String error) {
    return 'Error posting ad: $error';
  }

  @override
  String get noPetsAvailableForAdoption => 'No pets available for adoption';

  @override
  String get beFirstToPostPet => 'Be the first to post a pet for adoption!';

  @override
  String get errorLoadingPets => 'Error loading pets';

  @override
  String get productDetails => 'Product Details';

  @override
  String get wishlistTitle => 'My Wishlist';

  @override
  String get supportSmallBusinessTitle => 'Support Small Businesses';

  @override
  String get manageNearbyShopsTitle => 'Nearby Shops';

  @override
  String get manageAppFeaturesTitle => 'App Features';

  @override
  String get appFeaturesManagement => 'App Features Management';

  @override
  String get controlWhichFeaturesVisible =>
      'Control which features are visible to customers';

  @override
  String get supportSmallBusinessScreen => 'Support Small Businesses Screen';

  @override
  String get toggleVisibilityDescription =>
      'Toggle the visibility of the Support Small Businesses section in the customer app drawer';

  @override
  String get featureIsEnabled => 'Feature is ENABLED';

  @override
  String get featureIsDisabled => 'Feature is DISABLED';

  @override
  String get customersCanSeeThisScreen =>
      'Customers can see this screen in the app drawer';

  @override
  String get thisScreenIsHidden => 'This screen is hidden from customers';

  @override
  String get customizationOptions => 'Customization Options';

  @override
  String get menuTitle => 'Menu Title';

  @override
  String get menuIcon => 'Menu Icon';

  @override
  String get previewInAppDrawer => 'Preview in App Drawer';

  @override
  String get saveFeatureSettings => 'Save Feature Settings';

  @override
  String get saving => 'Saving...';

  @override
  String get featureSettingsSavedSuccessfully =>
      'Feature settings saved successfully!';

  @override
  String get howItWorks => 'How it works';

  @override
  String get howItWorksDescription =>
      '• When enabled, customers will see the menu item in their app drawer\n• When disabled, the menu item is completely hidden\n• Changes take effect immediately for all users\n• You can customize the title and icon anytime\n• Use the \"Shops\" tab to add businesses to this section';

  @override
  String get addNewShop => 'Add New Shop';

  @override
  String get chooseDestinationAndAddDetails =>
      'Choose destination and add shop details';

  @override
  String get addToCollection => 'Add to Collection:';

  @override
  String get shopImagesMultiple =>
      'Shop Images * (You can select multiple images)';

  @override
  String get tapToSelectShopImages => 'Tap to select shop images';

  @override
  String get youCanSelectMultipleImages => 'You can select multiple images';

  @override
  String get addMore => 'Add More';

  @override
  String get shopNameRequired => 'Shop Name *';

  @override
  String get pleaseEnterShopName => 'Please enter shop name';

  @override
  String get categoryRequired => 'Category *';

  @override
  String get categoriesForNearbyShops => 'Categories for nearby shops';

  @override
  String get categoriesForSmallBusinesses => 'Categories for small businesses';

  @override
  String get floor => 'Floor';

  @override
  String get groundFloor => 'Ground Floor';

  @override
  String get tellCustomersAboutShop => 'Tell customers about this shop...';

  @override
  String get tellCustomersAboutBusiness =>
      'Tell customers about this business...';

  @override
  String get addToNearbyShops => 'Add to Nearby Shops';

  @override
  String get addToSupportSmallBusinesses => 'Add to Support Small Businesses';

  @override
  String get adding => 'Adding...';

  @override
  String get shopAddedSuccessfully => 'Shop added successfully!';

  @override
  String get businessAddedSuccessfully => 'Business added successfully!';

  @override
  String get pleaseSelectAtLeastOneImage =>
      'Please select at least one image for the shop';

  @override
  String get manageShops => 'Manage Shops';

  @override
  String get editActivateOrRemoveShops =>
      'Edit, activate, or remove shops from collections';

  @override
  String noShopsInCollectionYet(String collection) {
    return 'No shops in $collection yet';
  }

  @override
  String get addYourFirstShop =>
      'Add your first shop using the \"Add Shop\" tab!';

  @override
  String images(int count) {
    return '$count images';
  }

  @override
  String floorLabel(String floor) {
    return 'Floor: $floor';
  }

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get activate => 'Activate';

  @override
  String get deactivate => 'Deactivate';

  @override
  String get deleteShop => 'Delete Shop';

  @override
  String areYouSureDeleteShop(String shopName) {
    return 'Are you sure you want to delete \"$shopName\"?';
  }

  @override
  String get shopDeletedSuccessfully => 'Shop deleted successfully';

  @override
  String get shopActivated => 'Shop activated';

  @override
  String get shopDeactivated => 'Shop deactivated';

  @override
  String errorUpdatingShop(String error) {
    return 'Error updating shop: $error';
  }

  @override
  String errorDeletingShop(String error) {
    return 'Error deleting shop: $error';
  }

  @override
  String get errorLoadingShops => 'Error loading shops';

  @override
  String get couldNotLaunchPhoneDialer => 'Could not launch phone dialer';

  @override
  String errorLaunchingDialer(String error) {
    return 'Error launching dialer: $error';
  }

  @override
  String get supportLocalEntrepreneurs => 'Support Local Entrepreneurs';

  @override
  String get helpSmallBusinessesThrive =>
      'Help small businesses thrive in your community';

  @override
  String get loadingBusinesses => 'Loading businesses...';

  @override
  String get errorLoadingBusinesses => 'Error loading businesses';

  @override
  String get noSmallBusinessesAvailable => 'No small businesses available';

  @override
  String get checkBackLaterForEntrepreneurs =>
      'Check back later for local entrepreneurs!';

  @override
  String get smallBusinessesUpdated => 'Small businesses updated';

  @override
  String get removedFromWishlist => 'Removed from wishlist';

  @override
  String get addedToWishlist => 'Added to wishlist';

  @override
  String get handmade => 'Handmade';

  @override
  String get artAndCrafts => 'Art & Crafts';

  @override
  String get foodAndBeverage => 'Food & Beverage';

  @override
  String get services => 'Services';

  @override
  String get technology => 'Technology';

  @override
  String get consulting => 'Consulting';

  @override
  String get retail => 'Retail';

  @override
  String get fitnessAndWellness => 'Fitness & Wellness';

  @override
  String get education => 'Education';

  @override
  String get other => 'Other';

  @override
  String get business => 'Business';

  @override
  String get heart => 'Heart';

  @override
  String get handshake => 'Handshake';

  @override
  String get support => 'Support';

  @override
  String get volunteer => 'Volunteer';

  @override
  String get group => 'Group';

  @override
  String get store => 'Store';

  @override
  String errorLoadingSettings(String error) {
    return 'Error loading settings: $error';
  }

  @override
  String errorSavingSettings(String error) {
    return 'Error saving settings: $error';
  }

  @override
  String get loadingFeatureSettings => 'Loading feature settings...';

  @override
  String get failedToUploadImages => 'Failed to upload images';

  @override
  String errorAddingShop(String error) {
    return 'Error adding shop: $error';
  }

  @override
  String get nearbyShops => 'Nearby Shops';

  @override
  String get myWishlist => 'My Wishlist';

  @override
  String get petAdoption => 'Pet Adoption';
}

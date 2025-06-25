import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Bubbles E-commerce App'**
  String get appTitle;

  /// No description provided for @homeScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Bubbles E-commerce'**
  String get homeScreenTitle;

  /// No description provided for @myBasketTitle.
  ///
  /// In en, this message translates to:
  /// **'My Basket'**
  String get myBasketTitle;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkoutTitle;

  /// No description provided for @orderConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Order Confirmed!'**
  String get orderConfirmedTitle;

  /// No description provided for @myOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrdersTitle;

  /// No description provided for @userProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get userProfileTitle;

  /// No description provided for @aboutUsTitle.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get aboutUsTitle;

  /// No description provided for @adminPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin Panel'**
  String get adminPanelTitle;

  /// No description provided for @continueShopping.
  ///
  /// In en, this message translates to:
  /// **'Continue Shopping'**
  String get continueShopping;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @subtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// No description provided for @shippingFee.
  ///
  /// In en, this message translates to:
  /// **'Shipping Fee'**
  String get shippingFee;

  /// No description provided for @grandTotal.
  ///
  /// In en, this message translates to:
  /// **'Grand Total'**
  String get grandTotal;

  /// No description provided for @placeOrder.
  ///
  /// In en, this message translates to:
  /// **'Place Order'**
  String get placeOrder;

  /// No description provided for @addToBasket.
  ///
  /// In en, this message translates to:
  /// **'Add to Basket'**
  String get addToBasket;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @relatedProducts.
  ///
  /// In en, this message translates to:
  /// **'Related Products'**
  String get relatedProducts;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @availability.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In Stock ({quantity})'**
  String inStock(Object quantity);

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @pricePerItem.
  ///
  /// In en, this message translates to:
  /// **'EGP {price} per item'**
  String pricePerItem(Object price);

  /// No description provided for @totalItemPrice.
  ///
  /// In en, this message translates to:
  /// **'Total: EGP {totalPrice}'**
  String totalItemPrice(Object totalPrice);

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @defaultShippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Default Shipping Address'**
  String get defaultShippingAddress;

  /// No description provided for @shippingArea.
  ///
  /// In en, this message translates to:
  /// **'Shipping Area'**
  String get shippingArea;

  /// No description provided for @buildingNumber.
  ///
  /// In en, this message translates to:
  /// **'Building Number'**
  String get buildingNumber;

  /// No description provided for @floorNumber.
  ///
  /// In en, this message translates to:
  /// **'Floor Number'**
  String get floorNumber;

  /// No description provided for @apartmentNumber.
  ///
  /// In en, this message translates to:
  /// **'Apartment Number'**
  String get apartmentNumber;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get loadingData;

  /// No description provided for @errorLoadingData.
  ///
  /// In en, this message translates to:
  /// **'Error loading data: {error}'**
  String errorLoadingData(Object error);

  /// No description provided for @noDataFound.
  ///
  /// In en, this message translates to:
  /// **'No data found.'**
  String get noDataFound;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Product Name'**
  String get productName;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @discount.
  ///
  /// In en, this message translates to:
  /// **'Discount (%)'**
  String get discount;

  /// No description provided for @quantityInStock.
  ///
  /// In en, this message translates to:
  /// **'Quantity in Stock'**
  String get quantityInStock;

  /// No description provided for @productDescription.
  ///
  /// In en, this message translates to:
  /// **'Product Description'**
  String get productDescription;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma-separated for related products)'**
  String get tags;

  /// No description provided for @addProductImages.
  ///
  /// In en, this message translates to:
  /// **'Add Product Images'**
  String get addProductImages;

  /// No description provided for @addMoreImages.
  ///
  /// In en, this message translates to:
  /// **'Add more images ({current}/{max})'**
  String addMoreImages(Object current, Object max);

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add New Category'**
  String get addCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get categoryName;

  /// No description provided for @categoryIcon.
  ///
  /// In en, this message translates to:
  /// **'Category Icon (emoji)'**
  String get categoryIcon;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @manageProducts.
  ///
  /// In en, this message translates to:
  /// **'Manage Products'**
  String get manageProducts;

  /// No description provided for @manageAreas.
  ///
  /// In en, this message translates to:
  /// **'Manage Areas'**
  String get manageAreas;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @addNewShippingArea.
  ///
  /// In en, this message translates to:
  /// **'Add New Shipping Area'**
  String get addNewShippingArea;

  /// No description provided for @areaName.
  ///
  /// In en, this message translates to:
  /// **'Area Name'**
  String get areaName;

  /// No description provided for @addArea.
  ///
  /// In en, this message translates to:
  /// **'Add Area'**
  String get addArea;

  /// No description provided for @shippingFeeAmount.
  ///
  /// In en, this message translates to:
  /// **'Shipping Fee'**
  String get shippingFeeAmount;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @totalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get totalSales;

  /// No description provided for @ordersByStatus.
  ///
  /// In en, this message translates to:
  /// **'Orders by Status'**
  String get ordersByStatus;

  /// No description provided for @orderId.
  ///
  /// In en, this message translates to:
  /// **'Order ID'**
  String get orderId;

  /// No description provided for @userEmail.
  ///
  /// In en, this message translates to:
  /// **'User Email'**
  String get userEmail;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @orderDate.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get orderDate;

  /// No description provided for @updateStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Status'**
  String get updateStatus;

  /// No description provided for @reorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get reorder;

  /// No description provided for @cancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Cancel Order'**
  String get cancelOrder;

  /// No description provided for @loadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Loading your orders...'**
  String get loadingOrders;

  /// No description provided for @errorLoadingOrders.
  ///
  /// In en, this message translates to:
  /// **'Error loading orders'**
  String get errorLoadingOrders;

  /// No description provided for @noOrdersYet.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

  /// No description provided for @orderHistoryWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your order history will appear here'**
  String get orderHistoryWillAppearHere;

  /// No description provided for @cannotReorderEmptyList.
  ///
  /// In en, this message translates to:
  /// **'Cannot reorder empty list of items.'**
  String get cannotReorderEmptyList;

  /// No description provided for @addingItemsToBasket.
  ///
  /// In en, this message translates to:
  /// **'Adding items to basket...'**
  String get addingItemsToBasket;

  /// No description provided for @uniqueItemsAddedToBasket.
  ///
  /// In en, this message translates to:
  /// **'{count} unique items added to your basket!'**
  String uniqueItemsAddedToBasket(Object count);

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @searchProducts.
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// No description provided for @searchResults.
  ///
  /// In en, this message translates to:
  /// **'Search Results'**
  String get searchResults;

  /// No description provided for @productsOnOffer.
  ///
  /// In en, this message translates to:
  /// **'Products on Offer'**
  String get productsOnOffer;

  /// No description provided for @noProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No products found for \"{query}\".'**
  String noProductsFound(Object query);

  /// No description provided for @noOffersFound.
  ///
  /// In en, this message translates to:
  /// **'No offers found.'**
  String get noOffersFound;

  /// No description provided for @shopByCategory.
  ///
  /// In en, this message translates to:
  /// **'Shop by Category'**
  String get shopByCategory;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @ourMission.
  ///
  /// In en, this message translates to:
  /// **'Our Mission'**
  String get ourMission;

  /// No description provided for @whatWeOffer.
  ///
  /// In en, this message translates to:
  /// **'What We Offer'**
  String get whatWeOffer;

  /// No description provided for @secureCheckout.
  ///
  /// In en, this message translates to:
  /// **'Secure Checkout'**
  String get secureCheckout;

  /// No description provided for @realtimeOrderTracking.
  ///
  /// In en, this message translates to:
  /// **'Real-time Order Tracking'**
  String get realtimeOrderTracking;

  /// No description provided for @diverseProductCatalog.
  ///
  /// In en, this message translates to:
  /// **'Diverse Product Catalog'**
  String get diverseProductCatalog;

  /// No description provided for @easyNavigation.
  ///
  /// In en, this message translates to:
  /// **'Easy Navigation'**
  String get easyNavigation;

  /// No description provided for @allRightsReserved.
  ///
  /// In en, this message translates to:
  /// **'© 2024 Bubbles E-commerce. All rights reserved.'**
  String get allRightsReserved;

  /// No description provided for @thankYouForYourOrder.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your order!'**
  String get thankYouForYourOrder;

  /// No description provided for @orderPlacedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Your order has been placed successfully.'**
  String get orderPlacedSuccessfully;

  /// No description provided for @orderDetails.
  ///
  /// In en, this message translates to:
  /// **'Order Details:'**
  String get orderDetails;

  /// No description provided for @shippingAddress.
  ///
  /// In en, this message translates to:
  /// **'Shipping Address:'**
  String get shippingAddress;

  /// No description provided for @imageLoadingError.
  ///
  /// In en, this message translates to:
  /// **'Error loading image for {itemName} ({imageUrl}): {error}'**
  String imageLoadingError(Object error, Object imageUrl, Object itemName);

  /// No description provided for @orderItemImageNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Order item image not supported'**
  String get orderItemImageNotSupported;

  /// No description provided for @orderCannotBeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Order cannot be cancelled'**
  String get orderCannotBeCancelled;

  /// No description provided for @orderCurrently.
  ///
  /// In en, this message translates to:
  /// **'This order is currently \"{status}\" and cannot be cancelled by you. Please contact customer support if you need further assistance.'**
  String orderCurrently(Object status);

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @areYouSureDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{productName}\"? This action cannot be undone.'**
  String areYouSureDeleteProduct(Object productName);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cloudinaryUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Cloudinary upload failed: {statusCode}. Check Cloudinary Console.'**
  String cloudinaryUploadFailed(Object statusCode);

  /// No description provided for @failedToUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image: {error}. Check internet/credentials.'**
  String failedToUploadImage(Object error);

  /// No description provided for @productAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product added successfully!'**
  String get productAddedSuccessfully;

  /// No description provided for @enterValidNumbers.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid numbers for price, discount, and quantity.'**
  String get enterValidNumbers;

  /// No description provided for @failedToAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Failed to add product: {error}'**
  String failedToAddProduct(Object error);

  /// No description provided for @categoryNameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Category name cannot be empty.'**
  String get categoryNameCannotBeEmpty;

  /// No description provided for @categoryIconCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Category icon cannot be empty.'**
  String get categoryIconCannotBeEmpty;

  /// No description provided for @categoryAdded.
  ///
  /// In en, this message translates to:
  /// **'Category \"{categoryName}\" added!'**
  String categoryAdded(Object categoryName);

  /// No description provided for @failedToAddCategory.
  ///
  /// In en, this message translates to:
  /// **'Failed to add category: {error}'**
  String failedToAddCategory(Object error);

  /// No description provided for @noCategoriesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No categories available. Please add some.'**
  String get noCategoriesAvailable;

  /// No description provided for @filterCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by Category'**
  String get filterCategory;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @noProductsFoundMatchingFilters.
  ///
  /// In en, this message translates to:
  /// **'No products found matching filters.'**
  String get noProductsFoundMatchingFilters;

  /// No description provided for @areaAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Area \"{areaName}\" added successfully!'**
  String areaAddedSuccessfully(Object areaName);

  /// No description provided for @failedToAddArea.
  ///
  /// In en, this message translates to:
  /// **'Failed to add area: {error}'**
  String failedToAddArea(Object error);

  /// No description provided for @areaDeleted.
  ///
  /// In en, this message translates to:
  /// **'Area \"{areaName}\" deleted.'**
  String areaDeleted(Object areaName);

  /// No description provided for @failedToDeleteArea.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete area: {error}'**
  String failedToDeleteArea(Object error);

  /// No description provided for @noShippingAreasFound.
  ///
  /// In en, this message translates to:
  /// **'No shipping areas found. Add some above.'**
  String get noShippingAreasFound;

  /// No description provided for @updateOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Update Order Status'**
  String get updateOrderStatus;

  /// No description provided for @newStatus.
  ///
  /// In en, this message translates to:
  /// **'New Status'**
  String get newStatus;

  /// No description provided for @orderStatusUpdated.
  ///
  /// In en, this message translates to:
  /// **'Order {orderId} status updated to \"{newStatus}\"!'**
  String orderStatusUpdated(Object newStatus, Object orderId);

  /// No description provided for @failedToUpdateOrderStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update order status: {error}'**
  String failedToUpdateOrderStatus(Object error);

  /// No description provided for @couldNotLaunchDialer.
  ///
  /// In en, this message translates to:
  /// **'Could not launch dialer for {phoneNumber}. Make sure a dialer app is installed.'**
  String couldNotLaunchDialer(Object phoneNumber);

  /// No description provided for @phoneNumberNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Phone number not available.'**
  String get phoneNumberNotAvailable;

  /// No description provided for @noOrderDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No order data available for analytics.'**
  String get noOrderDataAvailable;

  /// No description provided for @dashboardAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Analytics'**
  String get dashboardAnalytics;

  /// No description provided for @changePasswordComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Change Password functionality (coming soon)!'**
  String get changePasswordComingSoon;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @aboutUsContent.
  ///
  /// In en, this message translates to:
  /// **'Bubbles E-commerce is your one-stop shop for quality products at affordable prices. We are committed to providing excellent customer service and a seamless shopping experience.'**
  String get aboutUsContent;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDenied;

  /// No description provided for @verifyingAdminAccess.
  ///
  /// In en, this message translates to:
  /// **'Verifying admin access...'**
  String get verifyingAdminAccess;

  /// No description provided for @notAuthorizedToViewAdminPanel.
  ///
  /// In en, this message translates to:
  /// **'You are not authorized to view the admin panel.'**
  String get notAuthorizedToViewAdminPanel;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @addProductTabTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProductTabTitle;

  /// No description provided for @manageOfferCodesTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Offer Codes'**
  String get manageOfferCodesTitle;

  /// No description provided for @failedToLoadPreviousAddressDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to load previous address details'**
  String get failedToLoadPreviousAddressDetails;

  /// No description provided for @pleaseEnterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhoneNumber;

  /// No description provided for @pleaseEnterValidEgyptianPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid Egyptian phone number'**
  String get pleaseEnterValidEgyptianPhoneNumber;

  /// No description provided for @pleaseEnterFieldName.
  ///
  /// In en, this message translates to:
  /// **'Please enter {fieldName}'**
  String pleaseEnterFieldName(String fieldName);

  /// No description provided for @pleaseSelectShippingArea.
  ///
  /// In en, this message translates to:
  /// **'Please select shipping area'**
  String get pleaseSelectShippingArea;

  /// No description provided for @basketIsEmptyCanNotCheckout.
  ///
  /// In en, this message translates to:
  /// **'Basket is empty, cannot checkout'**
  String get basketIsEmptyCanNotCheckout;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Method'**
  String get selectPaymentMethod;

  /// No description provided for @cashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get cashOnDelivery;

  /// No description provided for @vodafoneCash.
  ///
  /// In en, this message translates to:
  /// **'Vodafone Cash'**
  String get vodafoneCash;

  /// No description provided for @etisalatCash.
  ///
  /// In en, this message translates to:
  /// **'Etisalat Cash'**
  String get etisalatCash;

  /// No description provided for @weCash.
  ///
  /// In en, this message translates to:
  /// **'We Cash'**
  String get weCash;

  /// No description provided for @instapay.
  ///
  /// In en, this message translates to:
  /// **'Instapay'**
  String get instapay;

  /// No description provided for @paymentInstruction.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred payment method'**
  String get paymentInstruction;

  /// No description provided for @processingOrder.
  ///
  /// In en, this message translates to:
  /// **'Processing Order'**
  String get processingOrder;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @shippingInformation.
  ///
  /// In en, this message translates to:
  /// **'Shipping Information'**
  String get shippingInformation;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @estimatedDelivery.
  ///
  /// In en, this message translates to:
  /// **'Estimated Delivery'**
  String get estimatedDelivery;

  /// No description provided for @freeShipping.
  ///
  /// In en, this message translates to:
  /// **'Free Shipping'**
  String get freeShipping;

  /// No description provided for @applyOfferCode.
  ///
  /// In en, this message translates to:
  /// **'Apply Offer Code'**
  String get applyOfferCode;

  /// No description provided for @offerCodeAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Offer code {code} added successfully'**
  String offerCodeAddedSuccessfully(String code);

  /// No description provided for @basketIsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your basket is empty'**
  String get basketIsEmpty;

  /// No description provided for @addProductsToGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Add some products to get started'**
  String get addProductsToGetStarted;

  /// No description provided for @clearBasket.
  ///
  /// In en, this message translates to:
  /// **'Clear Basket'**
  String get clearBasket;

  /// No description provided for @clearBasketConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Basket'**
  String get clearBasketConfirmTitle;

  /// No description provided for @clearBasketConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear your basket?'**
  String get clearBasketConfirmContent;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @basketCleared.
  ///
  /// In en, this message translates to:
  /// **'Basket cleared'**
  String get basketCleared;

  /// No description provided for @removeProduct.
  ///
  /// In en, this message translates to:
  /// **'Remove Product'**
  String get removeProduct;

  /// No description provided for @proceedToCheckout.
  ///
  /// In en, this message translates to:
  /// **'Proceed to Checkout'**
  String get proceedToCheckout;

  /// No description provided for @loadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading products...'**
  String get loadingProducts;

  /// No description provided for @errorLoadingProducts.
  ///
  /// In en, this message translates to:
  /// **'Error loading products'**
  String get errorLoadingProducts;

  /// No description provided for @productsIn.
  ///
  /// In en, this message translates to:
  /// **'Products in'**
  String get productsIn;

  /// No description provided for @checkBackLater.
  ///
  /// In en, this message translates to:
  /// **'Check back later'**
  String get checkBackLater;

  /// No description provided for @noProductsInCategory.
  ///
  /// In en, this message translates to:
  /// **'No products found in {category}'**
  String noProductsInCategory(String category);

  /// No description provided for @confirmOrder.
  ///
  /// In en, this message translates to:
  /// **'Confirm Order'**
  String get confirmOrder;

  /// No description provided for @orderTotal.
  ///
  /// In en, this message translates to:
  /// **'Order Total: EGP {total}'**
  String orderTotal(String total);

  /// No description provided for @deliveryTo.
  ///
  /// In en, this message translates to:
  /// **'Delivery to'**
  String get deliveryTo;

  /// No description provided for @areYouSureWantToPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to place this order?'**
  String get areYouSureWantToPlaceOrder;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @userNotLoggedInToPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'User not logged in to place order'**
  String get userNotLoggedInToPlaceOrder;

  /// No description provided for @productDoesNotExistInInventory.
  ///
  /// In en, this message translates to:
  /// **'Product {name} does not exist in inventory'**
  String productDoesNotExistInInventory(String name);

  /// No description provided for @notEnoughStock.
  ///
  /// In en, this message translates to:
  /// **'Not enough stock for {name}. Available: {available}, Requested: {requested}'**
  String notEnoughStock(String name, int available, int requested);

  /// No description provided for @failedToPlaceOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to place order: {error}'**
  String failedToPlaceOrder(String error);

  /// No description provided for @couldNotLaunchUrl.
  ///
  /// In en, this message translates to:
  /// **'Could not launch URL: {url}'**
  String couldNotLaunchUrl(String url);

  /// No description provided for @paymentDialerPrompt.
  ///
  /// In en, this message translates to:
  /// **'Dial {code} to pay EGP {amount}'**
  String paymentDialerPrompt(String code, String amount);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @itemsOrdered.
  ///
  /// In en, this message translates to:
  /// **'Items Ordered'**
  String get itemsOrdered;

  /// No description provided for @whatsAppUs.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Us'**
  String get whatsAppUs;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @needAssistance.
  ///
  /// In en, this message translates to:
  /// **'Need Assistance?'**
  String get needAssistance;

  /// No description provided for @supportTeamHelp.
  ///
  /// In en, this message translates to:
  /// **'Our support team is here to help you'**
  String get supportTeamHelp;

  /// No description provided for @availableBusinessHours.
  ///
  /// In en, this message translates to:
  /// **'Available during business hours: 9 AM - 6 PM'**
  String get availableBusinessHours;

  /// No description provided for @failedToCancelOrder.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel order: {error}'**
  String failedToCancelOrder(String error);

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @fieldNameMustBeNumber.
  ///
  /// In en, this message translates to:
  /// **'{fieldName} must be a number'**
  String fieldNameMustBeNumber(String fieldName);

  /// No description provided for @errorLoadingCategories.
  ///
  /// In en, this message translates to:
  /// **'Error loading categories: {error}'**
  String errorLoadingCategories(String error);

  /// No description provided for @searchProductsToAdd.
  ///
  /// In en, this message translates to:
  /// **'Search products to add'**
  String get searchProductsToAdd;

  /// No description provided for @searchProductByName.
  ///
  /// In en, this message translates to:
  /// **'Search product by name'**
  String get searchProductByName;

  /// No description provided for @selectedRelatedProducts.
  ///
  /// In en, this message translates to:
  /// **'Selected Related Products'**
  String get selectedRelatedProducts;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String items(int count);

  /// No description provided for @unnamedProduct.
  ///
  /// In en, this message translates to:
  /// **'Unnamed Product'**
  String get unnamedProduct;

  /// No description provided for @noOtherRelatedProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No other related products found'**
  String get noOtherRelatedProductsFound;

  /// No description provided for @markAsOffer.
  ///
  /// In en, this message translates to:
  /// **'Mark as Offer'**
  String get markAsOffer;

  /// No description provided for @pleaseLoginToViewOrders.
  ///
  /// In en, this message translates to:
  /// **'Please login to view your orders'**
  String get pleaseLoginToViewOrders;

  /// No description provided for @itemRemoved.
  ///
  /// In en, this message translates to:
  /// **'Item {name} removed'**
  String itemRemoved(String name);

  /// No description provided for @basketEmptyCannotCheckout.
  ///
  /// In en, this message translates to:
  /// **'Basket is empty, cannot checkout'**
  String get basketEmptyCannotCheckout;

  /// No description provided for @yesterdayAt.
  ///
  /// In en, this message translates to:
  /// **'Yesterday at {hour}:{minute}'**
  String yesterdayAt(String hour, String minute);

  /// No description provided for @todayAt.
  ///
  /// In en, this message translates to:
  /// **'Today at {hour}:{minute}'**
  String todayAt(String hour, String minute);

  /// No description provided for @at.
  ///
  /// In en, this message translates to:
  /// **'at'**
  String get at;

  /// No description provided for @mon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get mon;

  /// No description provided for @tue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tue;

  /// No description provided for @wed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wed;

  /// No description provided for @thu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thu;

  /// No description provided for @fri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get fri;

  /// No description provided for @sat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get sat;

  /// No description provided for @sun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sun;

  /// No description provided for @itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String itemCount(int count);

  /// No description provided for @discountPercentage.
  ///
  /// In en, this message translates to:
  /// **'Discount Percentage'**
  String get discountPercentage;

  /// No description provided for @addOfferCode.
  ///
  /// In en, this message translates to:
  /// **'Add Offer Code'**
  String get addOfferCode;

  /// No description provided for @offerCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Offer code is required'**
  String get offerCodeRequired;

  /// No description provided for @failedToAddOfferCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to add offer code: {error}'**
  String failedToAddOfferCode(String error);

  /// No description provided for @offerCodeRemoved.
  ///
  /// In en, this message translates to:
  /// **'Offer code {code} removed'**
  String offerCodeRemoved(String code);

  /// No description provided for @failedToRemoveOfferCode.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove offer code: {error}'**
  String failedToRemoveOfferCode(String error);

  /// No description provided for @noOfferCodesFound.
  ///
  /// In en, this message translates to:
  /// **'No offer codes found'**
  String get noOfferCodesFound;

  /// No description provided for @egyptianMobileNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Egyptian mobile number (11 digits)'**
  String get egyptianMobileNumberHint;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @offerCode.
  ///
  /// In en, this message translates to:
  /// **'Offer Code'**
  String get offerCode;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @offer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get offer;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @notAvailableAbbreviation.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get notAvailableAbbreviation;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @noCategoriesAvailableForFiltering.
  ///
  /// In en, this message translates to:
  /// **'No categories available for filtering'**
  String get noCategoriesAvailableForFiltering;

  /// No description provided for @noProductsFoundSimple.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFoundSimple;

  /// No description provided for @productDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product {productName} deleted successfully'**
  String productDeletedSuccessfully(String productName);

  /// No description provided for @failedToDeleteProduct.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete product: {error}'**
  String failedToDeleteProduct(String error);

  /// No description provided for @areYouSureDeleteProductAdmin.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{productName}\"? This action cannot be undone.'**
  String areYouSureDeleteProductAdmin(String productName);

  /// No description provided for @editProduct.
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProduct;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get pleaseSelectCategory;

  /// No description provided for @productUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Product updated successfully'**
  String get productUpdatedSuccessfully;

  /// No description provided for @failedToUpdateProduct.
  ///
  /// In en, this message translates to:
  /// **'Failed to update product: {error}'**
  String failedToUpdateProduct(String error);

  /// No description provided for @priceAndQuantityCannotBeNegative.
  ///
  /// In en, this message translates to:
  /// **'Price and quantity cannot be negative'**
  String get priceAndQuantityCannotBeNegative;

  /// No description provided for @failedToSearchProducts.
  ///
  /// In en, this message translates to:
  /// **'Failed to search products: {error}'**
  String failedToSearchProducts(String error);

  /// No description provided for @noRelatedProductsFound.
  ///
  /// In en, this message translates to:
  /// **'No related products found'**
  String get noRelatedProductsFound;

  /// No description provided for @noShippingAreasAvailable.
  ///
  /// In en, this message translates to:
  /// **'No shipping areas available'**
  String get noShippingAreasAvailable;

  /// No description provided for @orderItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items ordered'**
  String orderItems(int count);

  /// No description provided for @filterByCategory.
  ///
  /// In en, this message translates to:
  /// **'Filter by Category'**
  String get filterByCategory;

  /// No description provided for @selectShippingArea.
  ///
  /// In en, this message translates to:
  /// **'Select Shipping Area'**
  String get selectShippingArea;

  /// No description provided for @noProductsFoundGeneral.
  ///
  /// In en, this message translates to:
  /// **'No products found'**
  String get noProductsFoundGeneral;

  /// No description provided for @storeLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Store Location'**
  String get storeLocationTitle;

  /// No description provided for @nearbyShopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Shops'**
  String get nearbyShopsTitle;

  /// No description provided for @petAdoptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Pet Adoption'**
  String get petAdoptionTitle;

  /// No description provided for @findYourPerfectCompanion.
  ///
  /// In en, this message translates to:
  /// **'Find Your Perfect Companion'**
  String get findYourPerfectCompanion;

  /// No description provided for @lovingPetsLookingForHomes.
  ///
  /// In en, this message translates to:
  /// **'Loving pets looking for homes'**
  String get lovingPetsLookingForHomes;

  /// No description provided for @visitOurPhysicalStore.
  ///
  /// In en, this message translates to:
  /// **'Visit Our Physical Store'**
  String get visitOurPhysicalStore;

  /// No description provided for @storeInformation.
  ///
  /// In en, this message translates to:
  /// **'Store Information'**
  String get storeInformation;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @operatingHours.
  ///
  /// In en, this message translates to:
  /// **'Operating Hours'**
  String get operatingHours;

  /// No description provided for @findUsOnMap.
  ///
  /// In en, this message translates to:
  /// **'Find Us on Map'**
  String get findUsOnMap;

  /// No description provided for @interactiveMap.
  ///
  /// In en, this message translates to:
  /// **'Interactive Map'**
  String get interactiveMap;

  /// No description provided for @clickButtonsBelowToOpen.
  ///
  /// In en, this message translates to:
  /// **'Click buttons below to open in Google Maps'**
  String get clickButtonsBelowToOpen;

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @callStore.
  ///
  /// In en, this message translates to:
  /// **'Call Store'**
  String get callStore;

  /// No description provided for @storeFeatures.
  ///
  /// In en, this message translates to:
  /// **'Store Features'**
  String get storeFeatures;

  /// No description provided for @discoverLocalBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Discover Local Businesses'**
  String get discoverLocalBusinesses;

  /// No description provided for @supportYourLocalCommunity.
  ///
  /// In en, this message translates to:
  /// **'Support your local community'**
  String get supportYourLocalCommunity;

  /// No description provided for @nearbyShopsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Nearby shops updated'**
  String get nearbyShopsUpdated;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @browsePets.
  ///
  /// In en, this message translates to:
  /// **'Browse Pets'**
  String get browsePets;

  /// No description provided for @postAd.
  ///
  /// In en, this message translates to:
  /// **'Post Ad'**
  String get postAd;

  /// No description provided for @postPetForAdoption.
  ///
  /// In en, this message translates to:
  /// **'Post Pet for Adoption'**
  String get postPetForAdoption;

  /// No description provided for @helpPetFindLovingHome.
  ///
  /// In en, this message translates to:
  /// **'Help a pet find a loving home'**
  String get helpPetFindLovingHome;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotos;

  /// No description provided for @petInformation.
  ///
  /// In en, this message translates to:
  /// **'Pet Information'**
  String get petInformation;

  /// No description provided for @petName.
  ///
  /// In en, this message translates to:
  /// **'Pet Name'**
  String get petName;

  /// No description provided for @petType.
  ///
  /// In en, this message translates to:
  /// **'Pet Type'**
  String get petType;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @breed.
  ///
  /// In en, this message translates to:
  /// **'Breed'**
  String get breed;

  /// No description provided for @healthInformation.
  ///
  /// In en, this message translates to:
  /// **'Health Information'**
  String get healthInformation;

  /// No description provided for @vaccinated.
  ///
  /// In en, this message translates to:
  /// **'Vaccinated'**
  String get vaccinated;

  /// No description provided for @spayedNeutered.
  ///
  /// In en, this message translates to:
  /// **'Spayed/Neutered'**
  String get spayedNeutered;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @yourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Your Phone Number'**
  String get yourPhoneNumber;

  /// No description provided for @postPetForAdoptionButton.
  ///
  /// In en, this message translates to:
  /// **'Post Pet for Adoption'**
  String get postPetForAdoptionButton;

  /// No description provided for @posting.
  ///
  /// In en, this message translates to:
  /// **'Posting...'**
  String get posting;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @pleaseEnterPetName.
  ///
  /// In en, this message translates to:
  /// **'Please enter pet name'**
  String get pleaseEnterPetName;

  /// No description provided for @pleaseEnterAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter age'**
  String get pleaseEnterAge;

  /// No description provided for @pleaseEnterDescription.
  ///
  /// In en, this message translates to:
  /// **'Please enter description'**
  String get pleaseEnterDescription;

  /// No description provided for @pleaseEnterYourName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterYourName;

  /// No description provided for @pleaseAddAtLeastOnePhoto.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one photo'**
  String get pleaseAddAtLeastOnePhoto;

  /// No description provided for @petAdPostedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Pet ad posted successfully!'**
  String get petAdPostedSuccessfully;

  /// No description provided for @errorPostingAd.
  ///
  /// In en, this message translates to:
  /// **'Error posting ad: {error}'**
  String errorPostingAd(String error);

  /// No description provided for @noPetsAvailableForAdoption.
  ///
  /// In en, this message translates to:
  /// **'No pets available for adoption'**
  String get noPetsAvailableForAdoption;

  /// No description provided for @beFirstToPostPet.
  ///
  /// In en, this message translates to:
  /// **'Be the first to post a pet for adoption!'**
  String get beFirstToPostPet;

  /// No description provided for @errorLoadingPets.
  ///
  /// In en, this message translates to:
  /// **'Error loading pets'**
  String get errorLoadingPets;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @wishlistTitle.
  ///
  /// In en, this message translates to:
  /// **'My Wishlist'**
  String get wishlistTitle;

  /// No description provided for @supportSmallBusinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Support Small Businesses'**
  String get supportSmallBusinessTitle;

  /// No description provided for @manageNearbyShopsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Shops'**
  String get manageNearbyShopsTitle;

  /// No description provided for @manageAppFeaturesTitle.
  ///
  /// In en, this message translates to:
  /// **'App Features'**
  String get manageAppFeaturesTitle;

  /// No description provided for @appFeaturesManagement.
  ///
  /// In en, this message translates to:
  /// **'App Features Management'**
  String get appFeaturesManagement;

  /// No description provided for @controlWhichFeaturesVisible.
  ///
  /// In en, this message translates to:
  /// **'Control which features are visible to customers'**
  String get controlWhichFeaturesVisible;

  /// No description provided for @supportSmallBusinessScreen.
  ///
  /// In en, this message translates to:
  /// **'Support Small Businesses Screen'**
  String get supportSmallBusinessScreen;

  /// No description provided for @toggleVisibilityDescription.
  ///
  /// In en, this message translates to:
  /// **'Toggle the visibility of the Support Small Businesses section in the customer app drawer'**
  String get toggleVisibilityDescription;

  /// No description provided for @featureIsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Feature is ENABLED'**
  String get featureIsEnabled;

  /// No description provided for @featureIsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Feature is DISABLED'**
  String get featureIsDisabled;

  /// No description provided for @customersCanSeeThisScreen.
  ///
  /// In en, this message translates to:
  /// **'Customers can see this screen in the app drawer'**
  String get customersCanSeeThisScreen;

  /// No description provided for @thisScreenIsHidden.
  ///
  /// In en, this message translates to:
  /// **'This screen is hidden from customers'**
  String get thisScreenIsHidden;

  /// No description provided for @customizationOptions.
  ///
  /// In en, this message translates to:
  /// **'Customization Options'**
  String get customizationOptions;

  /// No description provided for @menuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu Title'**
  String get menuTitle;

  /// No description provided for @menuIcon.
  ///
  /// In en, this message translates to:
  /// **'Menu Icon'**
  String get menuIcon;

  /// No description provided for @previewInAppDrawer.
  ///
  /// In en, this message translates to:
  /// **'Preview in App Drawer'**
  String get previewInAppDrawer;

  /// No description provided for @saveFeatureSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Feature Settings'**
  String get saveFeatureSettings;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @featureSettingsSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Feature settings saved successfully!'**
  String get featureSettingsSavedSuccessfully;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @howItWorksDescription.
  ///
  /// In en, this message translates to:
  /// **'• When enabled, customers will see the menu item in their app drawer\n• When disabled, the menu item is completely hidden\n• Changes take effect immediately for all users\n• You can customize the title and icon anytime\n• Use the \"Shops\" tab to add businesses to this section'**
  String get howItWorksDescription;

  /// No description provided for @addNewShop.
  ///
  /// In en, this message translates to:
  /// **'Add New Shop'**
  String get addNewShop;

  /// No description provided for @chooseDestinationAndAddDetails.
  ///
  /// In en, this message translates to:
  /// **'Choose destination and add shop details'**
  String get chooseDestinationAndAddDetails;

  /// No description provided for @addToCollection.
  ///
  /// In en, this message translates to:
  /// **'Add to Collection:'**
  String get addToCollection;

  /// No description provided for @shopImagesMultiple.
  ///
  /// In en, this message translates to:
  /// **'Shop Images * (You can select multiple images)'**
  String get shopImagesMultiple;

  /// No description provided for @tapToSelectShopImages.
  ///
  /// In en, this message translates to:
  /// **'Tap to select shop images'**
  String get tapToSelectShopImages;

  /// No description provided for @youCanSelectMultipleImages.
  ///
  /// In en, this message translates to:
  /// **'You can select multiple images'**
  String get youCanSelectMultipleImages;

  /// No description provided for @addMore.
  ///
  /// In en, this message translates to:
  /// **'Add More'**
  String get addMore;

  /// No description provided for @shopNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Shop Name *'**
  String get shopNameRequired;

  /// No description provided for @pleaseEnterShopName.
  ///
  /// In en, this message translates to:
  /// **'Please enter shop name'**
  String get pleaseEnterShopName;

  /// No description provided for @categoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Category *'**
  String get categoryRequired;

  /// No description provided for @categoriesForNearbyShops.
  ///
  /// In en, this message translates to:
  /// **'Categories for nearby shops'**
  String get categoriesForNearbyShops;

  /// No description provided for @categoriesForSmallBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Categories for small businesses'**
  String get categoriesForSmallBusinesses;

  /// No description provided for @floor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get floor;

  /// No description provided for @groundFloor.
  ///
  /// In en, this message translates to:
  /// **'Ground Floor'**
  String get groundFloor;

  /// No description provided for @tellCustomersAboutShop.
  ///
  /// In en, this message translates to:
  /// **'Tell customers about this shop...'**
  String get tellCustomersAboutShop;

  /// No description provided for @tellCustomersAboutBusiness.
  ///
  /// In en, this message translates to:
  /// **'Tell customers about this business...'**
  String get tellCustomersAboutBusiness;

  /// No description provided for @addToNearbyShops.
  ///
  /// In en, this message translates to:
  /// **'Add to Nearby Shops'**
  String get addToNearbyShops;

  /// No description provided for @addToSupportSmallBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Add to Support Small Businesses'**
  String get addToSupportSmallBusinesses;

  /// No description provided for @adding.
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get adding;

  /// No description provided for @shopAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Shop added successfully!'**
  String get shopAddedSuccessfully;

  /// No description provided for @businessAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Business added successfully!'**
  String get businessAddedSuccessfully;

  /// No description provided for @pleaseSelectAtLeastOneImage.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one image for the shop'**
  String get pleaseSelectAtLeastOneImage;

  /// No description provided for @manageShops.
  ///
  /// In en, this message translates to:
  /// **'Manage Shops'**
  String get manageShops;

  /// No description provided for @editActivateOrRemoveShops.
  ///
  /// In en, this message translates to:
  /// **'Edit, activate, or remove shops from collections'**
  String get editActivateOrRemoveShops;

  /// No description provided for @noShopsInCollectionYet.
  ///
  /// In en, this message translates to:
  /// **'No shops in {collection} yet'**
  String noShopsInCollectionYet(String collection);

  /// No description provided for @addYourFirstShop.
  ///
  /// In en, this message translates to:
  /// **'Add your first shop using the \"Add Shop\" tab!'**
  String get addYourFirstShop;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'{count} images'**
  String images(int count);

  /// No description provided for @floorLabel.
  ///
  /// In en, this message translates to:
  /// **'Floor: {floor}'**
  String floorLabel(String floor);

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get activate;

  /// No description provided for @deactivate.
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get deactivate;

  /// No description provided for @deleteShop.
  ///
  /// In en, this message translates to:
  /// **'Delete Shop'**
  String get deleteShop;

  /// No description provided for @areYouSureDeleteShop.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{shopName}\"?'**
  String areYouSureDeleteShop(String shopName);

  /// No description provided for @shopDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Shop deleted successfully'**
  String get shopDeletedSuccessfully;

  /// No description provided for @shopActivated.
  ///
  /// In en, this message translates to:
  /// **'Shop activated'**
  String get shopActivated;

  /// No description provided for @shopDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Shop deactivated'**
  String get shopDeactivated;

  /// No description provided for @errorUpdatingShop.
  ///
  /// In en, this message translates to:
  /// **'Error updating shop: {error}'**
  String errorUpdatingShop(String error);

  /// No description provided for @errorDeletingShop.
  ///
  /// In en, this message translates to:
  /// **'Error deleting shop: {error}'**
  String errorDeletingShop(String error);

  /// No description provided for @errorLoadingShops.
  ///
  /// In en, this message translates to:
  /// **'Error loading shops'**
  String get errorLoadingShops;

  /// No description provided for @couldNotLaunchPhoneDialer.
  ///
  /// In en, this message translates to:
  /// **'Could not launch phone dialer'**
  String get couldNotLaunchPhoneDialer;

  /// No description provided for @errorLaunchingDialer.
  ///
  /// In en, this message translates to:
  /// **'Error launching dialer: {error}'**
  String errorLaunchingDialer(String error);

  /// No description provided for @supportLocalEntrepreneurs.
  ///
  /// In en, this message translates to:
  /// **'Support Local Entrepreneurs'**
  String get supportLocalEntrepreneurs;

  /// No description provided for @helpSmallBusinessesThrive.
  ///
  /// In en, this message translates to:
  /// **'Help small businesses thrive in your community'**
  String get helpSmallBusinessesThrive;

  /// No description provided for @loadingBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Loading businesses...'**
  String get loadingBusinesses;

  /// No description provided for @errorLoadingBusinesses.
  ///
  /// In en, this message translates to:
  /// **'Error loading businesses'**
  String get errorLoadingBusinesses;

  /// No description provided for @noSmallBusinessesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No small businesses available'**
  String get noSmallBusinessesAvailable;

  /// No description provided for @checkBackLaterForEntrepreneurs.
  ///
  /// In en, this message translates to:
  /// **'Check back later for local entrepreneurs!'**
  String get checkBackLaterForEntrepreneurs;

  /// No description provided for @smallBusinessesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Small businesses updated'**
  String get smallBusinessesUpdated;

  /// No description provided for @removedFromWishlist.
  ///
  /// In en, this message translates to:
  /// **'Removed from wishlist'**
  String get removedFromWishlist;

  /// No description provided for @addedToWishlist.
  ///
  /// In en, this message translates to:
  /// **'Added to wishlist'**
  String get addedToWishlist;

  /// No description provided for @handmade.
  ///
  /// In en, this message translates to:
  /// **'Handmade'**
  String get handmade;

  /// No description provided for @artAndCrafts.
  ///
  /// In en, this message translates to:
  /// **'Art & Crafts'**
  String get artAndCrafts;

  /// No description provided for @foodAndBeverage.
  ///
  /// In en, this message translates to:
  /// **'Food & Beverage'**
  String get foodAndBeverage;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @technology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get technology;

  /// No description provided for @consulting.
  ///
  /// In en, this message translates to:
  /// **'Consulting'**
  String get consulting;

  /// No description provided for @retail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get retail;

  /// No description provided for @fitnessAndWellness.
  ///
  /// In en, this message translates to:
  /// **'Fitness & Wellness'**
  String get fitnessAndWellness;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @business.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get business;

  /// No description provided for @heart.
  ///
  /// In en, this message translates to:
  /// **'Heart'**
  String get heart;

  /// No description provided for @handshake.
  ///
  /// In en, this message translates to:
  /// **'Handshake'**
  String get handshake;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @volunteer.
  ///
  /// In en, this message translates to:
  /// **'Volunteer'**
  String get volunteer;

  /// No description provided for @group.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get group;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @errorLoadingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error loading settings: {error}'**
  String errorLoadingSettings(String error);

  /// No description provided for @errorSavingSettings.
  ///
  /// In en, this message translates to:
  /// **'Error saving settings: {error}'**
  String errorSavingSettings(String error);

  /// No description provided for @loadingFeatureSettings.
  ///
  /// In en, this message translates to:
  /// **'Loading feature settings...'**
  String get loadingFeatureSettings;

  /// No description provided for @failedToUploadImages.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload images'**
  String get failedToUploadImages;

  /// No description provided for @errorAddingShop.
  ///
  /// In en, this message translates to:
  /// **'Error adding shop: {error}'**
  String errorAddingShop(String error);

  /// No description provided for @nearbyShops.
  ///
  /// In en, this message translates to:
  /// **'Nearby Shops'**
  String get nearbyShops;

  /// No description provided for @myWishlist.
  ///
  /// In en, this message translates to:
  /// **'My Wishlist'**
  String get myWishlist;

  /// No description provided for @petAdoption.
  ///
  /// In en, this message translates to:
  /// **'Pet Adoption'**
  String get petAdoption;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

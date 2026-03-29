# دليل الإعداد والتشغيل - Setup Guide

## المتطلبات الأساسية

1. **Flutter SDK** (الإصدار 3.0.0 أو أحدث)
2. **Android Studio** أو **VS Code** مع إضافة Flutter
3. **Android SDK** (API Level 21 أو أحدث)
4. **جهاز Android** أو **Emulator** للاختبار

## خطوات الإعداد

### 1. تثبيت الحزم المطلوبة

```bash
flutter pub get
```

### 2. إعداد الأيقونات

يجب إضافة أيقونات التطبيق في المجلدات التالية:
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` (48x48)
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` (72x72)
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` (96x96)
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` (144x144)
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` (192x192)

يمكنك استخدام أداة مثل [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons) لتوليد الأيقونات تلقائياً.

### 3. الصلاحيات المطلوبة

التطبيق يحتاج إلى الصلاحيات التالية في Android:
- `QUERY_ALL_PACKAGES` - لفحص التطبيقات المثبتة
- `INTERNET` - لفحص حالة الشبكة
- `ACCESS_NETWORK_STATE` - لفحص حالة الاتصال
- `ACCESS_WIFI_STATE` - لفحص حالة WiFi

**ملاحظة:** صلاحية `QUERY_ALL_PACKAGES` قد تحتاج إلى موافقة خاصة من Google Play Store.

### 4. تشغيل التطبيق

```bash
flutter run
```

أو من Android Studio:
1. افتح المشروع
2. اختر جهاز Android أو Emulator
3. اضغط على زر Run

## الحساب الافتراضي

- **اسم المستخدم:** `admin`
- **كلمة المرور:** `admin123`

يمكنك إنشاء حساب جديد من شاشة تسجيل الدخول.

## الميزات الرئيسية

### 🔒 فحص الأمان
- فحص شامل للتطبيقات المثبتة
- تحليل الصلاحيات الخطيرة
- كشف التطبيقات المشبوهة

### 📡 فحص الشبكة
- فحص نوع الاتصال (WiFi / Mobile)
- كشف الشبكات العامة وغير الآمنة
- تحذيرات أمنية فورية

### 📱 فحص النظام
- معلومات إصدار Android
- حالة التحديثات الأمنية
- كشف وضع المطور
- كشف الجذر (Root)

### 📊 التقارير
- تقارير أسبوعية وشهرية
- إحصائيات درجة الأمان
- سجل الفحوصات السابقة

### 🔔 التنبيهات
- تنبيهات فورية عند اكتشاف مخاطر
- إشعارات محلية
- سجل التنبيهات

## البنية التقنية

```
lib/
├── main.dart                 # نقطة الدخول
├── models/                   # نماذج البيانات
│   ├── app_info.dart
│   ├── network_info.dart
│   ├── security_scan.dart
│   └── system_info.dart
├── providers/               # إدارة الحالة
│   ├── auth_provider.dart
│   └── security_provider.dart
├── screens/                 # الشاشات
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── apps_scan_screen.dart
│   ├── network_scan_screen.dart
│   ├── system_scan_screen.dart
│   ├── notifications_screen.dart
│   └── reports_screen.dart
├── services/                # الخدمات
│   ├── database_service.dart
│   ├── notification_service.dart
│   └── security_scanner_service.dart
└── utils/                   # أدوات مساعدة
    └── permission_utils.dart
```

## ملاحظات مهمة

1. **الخصوصية:** جميع البيانات تُخزن محلياً على الجهاز فقط
2. **الأمان:** لا يتم إرسال أي بيانات إلى سيرفرات خارجية
3. **الأداء:** قد يستغرق الفحص الأول بعض الوقت حسب عدد التطبيقات
4. **الصلاحيات:** بعض الصلاحيات قد تحتاج موافقة المستخدم

## استكشاف الأخطاء

### مشكلة: لا تظهر التطبيقات
- تأكد من منح الصلاحيات المطلوبة
- تحقق من إصدار Android (يجب أن يكون 5.0+)

### مشكلة: لا يعمل فحص الشبكة
- تأكد من تفعيل WiFi أو البيانات
- تحقق من الصلاحيات في إعدادات التطبيق

### مشكلة: الأخطاء في البناء
```bash
flutter clean
flutter pub get
flutter run
```

## التطوير المستقبلي

- [ ] دعم iOS
- [ ] تحسين خوارزمية كشف التطبيقات الخطيرة
- [ ] إضافة المزيد من التحذيرات الأمنية
- [ ] تحسين واجهة المستخدم
- [ ] إضافة تصدير التقارير

## الترخيص

هذا المشروع مفتوح المصدر ومتاح للاستخدام الحر.


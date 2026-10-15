# Madomi AI Manga/Manhwa Reader & Translator (Kaggle GPU Edition)

مشروع متكامل لقراءة وترجمة قصص المانجا والمانهوا باستخدام الذكاء الاصطناعي مع بطاقة رسوميات مجانية (GPU T4 x2) على Kaggle وتطبيق Flutter للهواتف والويب.

---

## ⚡ دليل التشغيل السريع في 3 دقائق (Quick Start Guide)

### 1️⃣ الخطوة الأولى: تشغيل السيرفر على Kaggle (دقيقة واحدة)
1. ادخل إلى [Kaggle Notebooks](https://www.kaggle.com/code) واضغط على **New Notebook**.
2. من القائمة الجانبية اليمنى (**Settings**):
   - اضبط **Accelerator** على **GPU T4 x2** (أو **GPU P100**).
   - تأكد من تفعيل الإنترنت: **Internet** -> **ON**.
3. افتح ملف `kaggle_backend/KAGGLE_NOTEBOOK_RUNNER.py`، وانسخ كل محتواه.
4. الصق الكود داخل خلية واحدة (**Single Cell**) في Kaggle ثم اضغط **Run**.
5. سيبدأ السيرفر في تثبيت المكتبات وتشغيل FastAPI وفتح نفق Cloudflare. بعد حوالي 60 ثانية، سيظهر لك في المخرجات رابط عام بهذا الشكل:
   ```text
   🔗 https://xxxx-xxxx-xxxx.trycloudflare.com
   ```
   **انسخ هذا الرابط**.

---

### 2️⃣ الخطوة الثانية: تشغيل تطبيق Flutter (دقيقة واحدة)
1. افتح موجه الأوامر (Terminal) داخل مجلد `flutter_app/`:
   ```bash
   cd flutter_app
   ```
2. قم بتهيئة ملفات المنصة وتثبيت الحزم المطلوبة:
   ```bash
   flutter create .
   flutter pub get
   flutter run
   ```
   *(يمكنك تشغيله على محاكي أندرويد، هاتف متصل بـ USB، أو كمتصفح Chrome)*.

---

### 3️⃣ الخطوة الثالثة: ربط التطبيق والترجمة الفورية (دقيقة واحدة)
1. في أعلى شاشة التطبيق، اضغط على زر **"ربط Kaggle URL"**.
2. الصق رابط **Cloudflare** (`https://xxxx.trycloudflare.com`).
3. *(اختياري)*: ضع مفتاح **Gemini API Key** الخاص بك إذا أردت ترجمة سياقية ذكية فائقة الدقة بأسماء الشخصيات وجنسهم، أو اتركه فارغاً للاعتماد على المترجم الفوري المدمج مجاناً.
4. **ابدأ القراءة والترجمة**:
   - **Web Mode**: تصفح أي موقع مانهوا، واضغط على أيقونة الصاعقة أو زر الترجمة فوق الصور لترى كيف يتم مسح النص الإنجليزي بالـ Inpainting وكتابة العربي بدقة.
   - **Local Reader**: اختر ملف فصل بصيغة **CBZ / ZIP** أو صور مجلد من جهازك وترجم الصفحات دفعة واحدة.
   - **Glossary**: اسحب أسماء الشخصيات وجنسها تلقائياً من **AniList** لتوحيد الترجمة وضبط الضمائر.

---

## 📁 هيكلية المشروع
```text
madomi_full_stack_kaggle/
├── README.md
├── kaggle_backend/
│   └── KAGGLE_NOTEBOOK_RUNNER.py   # سكريبت الخلية الواحدة في Kaggle (FastAPI + EasyOCR + Inpainting + Tunnel)
└── flutter_app/
    ├── pubspec.yaml                 # تبعات التطبيق
    ├── assets/js/injector.js        # كود حقن الترجمة في متصفح المواقع
    ├── android/app/src/main/AndroidManifest.xml
    └── lib/
        ├── main.dart                # الواجهة الرئيسية وتنسيق النوافذ
        ├── models/models.dart       # هياكل البيانات (الفقاعات، القاموس، النتائج)
        ├── screens/
        │   ├── web_mode_screen.dart     # متصفح مواقع المانهوا مع كاشف الصور
        │   ├── local_reader_screen.dart # قارئ الفصول المحلية (CBZ/ZIP/Images)
        │   └── glossary_screen.dart     # إدارة قاموس الشخصيات وسحبها من AniList
        ├── services/
        │   ├── translation_cache_service.dart # إدارة الاتصال بسيرفر Kaggle والتخزين المؤقت
        │   ├── anilist_glossary_service.dart  # الربط مع GraphQL API لموقع AniList
        │   └── local_cbz_service.dart         # استخراج وقراءة ملفات CBZ
        └── widgets/
            └── translated_manga_page.dart     # عرض الصفحة الممسوحة وإعادة كتابة النص العربي
```

---

## 🛠️ التقنيات المستخدمة
* **EasyOCR (GPU)**: رصد مواقع النصوص والفقاعات وإحداثياتها الدقيقة `(x, y, w, h)`.
* **OpenCV Inpainting (`cv2.inpaint`)**: مسح النصوص الأصلية تماماً مع إعادة توليد خلفية الرسم دون تشويه.
* **Cloudflare Tunnel (`cloudflared`)**: رابط مباشر ومجاني بالكامل بدون الحاجة لحساب أو توكن Ngrok.
* **AniList GraphQL API**: ضبط أسماء الأبطال وجنسهم لترجمة دقيقة وسليمة للضمائر.

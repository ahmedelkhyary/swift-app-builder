# منشئ التطبيقات (Swift App Builder)

[English](README.md) · **العربية**

أداة ويب مبنية بـ Flutter لإعداد **تطبيقات جوال بعلامة بيضاء لمكاتب استقدام العمالة المنزلية**.
كل التطبيقات المُنتَجة تعمل بنفس منطق العمل؛ والاختلاف فقط في الهوية البصرية
والوحدات المفعّلة وقالب التصميم.

يمرّ فريقنا عبر خمس خطوات وتنتج الأداة ملف إعدادات JSON **موثّقًا ومُرقّمًا بالإصدارات**،
ستستهلكه لاحقًا خطوات توليد التطبيق (غير موجودة في هذا المستودع بعد).

**العرض المباشر:** https://ahmedelkhyary.github.io/swift-app-builder/

## ماذا تفعل الأداة

| الخطوة | المحتوى |
|--------|---------|
| 1. معلومات التطبيق | اسم التطبيق (عربي/إنجليزي)، معرّف التطبيق (يُولَّد تلقائيًا وقابل للتعديل)، حزمة أندرويد، معرّف iOS (أو «نفس أندرويد»)، بيانات العميل (الاسم والبريد الأساسي والهاتف) وبريد الدعم الاختياري |
| 2. الهوية البصرية | منتقي ألوان مدمج للّون الأساسي والثانوي وخلفية شاشة البداية (HEX وRGB وقطّارة وفحص التباين واستخراج الألوان من الشعار)، الشعار، أيقونة التطبيق، شعار شاشة البداية، الخط |
| 3. اللغات | اللغة الافتراضية واللغات المدعومة |
| 4. القوالب | وحدات الخدمة المفعّلة، ثلاثة قوالب تصميم (البسيط وفاخر وبريميوم) (يمكن تحديد أكثر من قالب و**مقارنتها** جنبًا إلى جنب)، و**معاينة تفاعلية كاملة** على هاتف |
| 5. الملخص | مراجعة، JSON منسّق، تقرير التحقق من المخطط، حفظ إصدار جديد، تنزيل JSON، سجل الإصدارات مع «استعادة كمسودة جديدة» |

أهم الخصائص:

- **عربي أولًا مع دعم RTL** وزر للتبديل إلى الإنجليزية. واجهة الأداة نفسها مترجمة بملفات ARB.
- **معاينة تفاعلية وليست صورًا.** المعاينة هي تطبيق `recruitment_ui` الحقيقي بيانات وهمية:
  تسجيل الدخول والتحقق، الرئيسية، وخدمات الأفراد والساعة والوساطة حتى الدفع والنجاح.
  لا رسائل SMS ولا مدفوعات ولا حجوزات حقيقية إطلاقًا.
- **القوالب مجرد أنماط تصميم.** كل القوالب تشترك في نفس المنطق والمسارات وتختلف
  في عناصر التصميم فقط (البطاقات، الترويسة، الأزرار، الحقول، شريط التنقل، الانتقالات).
- **إعدادات موثّقة ومحفوظة بإضافة فقط.** كل حفظ ينشئ إصدارًا جديدًا غير قابل للتعديل
  بعد التحقق من `assets/config.schema.json`، ولا يمكن تخزين أسرار لأن المخطط يمنع الحقول غير المعروفة.

## هيكل المستودع

```
lib/                       الأداة (Riverpod + go_router + ARB)
packages/recruitment_ui/   التطبيق التفاعلي والقوالب (له README خاص)
assets/config.schema.json  مخطط JSON للإعدادات
docs/CONFIG.md             مرجع الإعدادات
test/                      اختبارات الوحدة والواجهة
```

## التشغيل

المتطلبات: Flutter 3.41+.

```bash
flutter pub get
flutter run -d chrome
```

الخطوط (IBM Plex وCairo) تُحمَّل من Google Fonts وقت التشغيل، فيلزم اتصال بالإنترنت.

### الاختبارات

```bash
flutter analyze
flutter test
(cd packages/recruitment_ui && flutter test)
```

## إرسال الطلب (Firebase)

تنتهي الخطوة 5 بزر **إرسال الطلب**: تُحفظ بيانات المعالج في Firestore داخل
`app_requests/{appId}` بحالة `pending` مع `createdAt` و`updatedAt`، وتُرفع صورتا الشعار والأيقونة
إلى Storage داخل `app_requests/{appId}/` ويُحفظ رابطا التنزيل في المستند. إن وُجد طلب بنفس المعرّف
يُطلب من المستخدم تأكيد التحديث (ويبقى `createdAt` كما هو).

الإعداد: أنشئ مشروع Firebase وتطبيق ويب وفعّل Firestore وStorage، وانسخ `.env.example` إلى `.env`
واملأه، ثم شغّل `flutter run -d chrome --dart-define-from-file=.env`، وانشر القواعد من
`firestore.rules` و`storage.rules`. على GitHub Pages أضف نفس المفاتيح كأسرار للمستودع.
بدون المفاتيح يعمل التطبيق لكن الإرسال يعرض رسالة أن Firebase غير مضبوط.

## خط البناء (Azure DevOps)

بعد حفظ الطلب (`status: "pending"`) تُطلِق دالة سحابية (Cloud Function) تشغيلة من
Azure DevOps Pipeline بمعرّف الطلب فقط؛ يقرأ الـ pipeline كل شيء آخر بنفسه. يتوقف
هذا المستودع عند "صار لدى الـ pipeline بيانات الطلب وأصوله على القرص" — توليد
التطبيق وبناؤه للمتاجر خطوة مؤجَّلة (تعليق في `pipeline/azure-pipelines.yml`)
وليست جزءًا من هذا المستودع بعد.

```
تطبيق Flutter ─◁ Firestore app_requests/{id} (status: pending)
       │                       ▲
       │ POST {requestId}      │ فحص دوري كل 5 دقائق
       ▼                       │ (sweepPendingAppRequests، شبكة أمان
  functions/: dispatchAppRequest ─◁ Azure DevOps REST API   لطلب لم يصل)
                                       (تشغيل run)
                        │
                        ▼
      pipeline/azure-pipelines.yml ─◁ pipeline/scripts/request.mjs
        (fetch: يقرأ المستند ويحمّل الأصول إلى build_input/،
         ثم — متى وُجد مولّد — يبني، ثم يكتب الحالة في المستند)
```

ليست مُشغَّلة بـ trigger على Firestore: قاعدة بيانات Firestore لهذا المشروع قد
تكون في منطقة لا تدعم Cloud Functions من الجيل الثاني تشغيل الحساب فيها (وأي
trigger خلفي على Firestore يجب أن يعمل في نفس منطقة القاعدة)، لذا يستدعي
التطبيق `dispatchAppRequest` مباشرة بعد كتابة المستند بحالة "pending"، وتعمل
`sweepPendingAppRequests` (عبر Cloud Scheduler كل 5 دقائق) كشبكة أمان لأي نداء
لم يصل (تبويب مُغلَق، اتصال منقطع). كلتاهما في `us-central1` بصرف النظر عن
منطقة Firestore نفسها.

راجع [`docs/CONFIG.md`](docs/CONFIG.md#request-status-and-the-pipeline-fields)
لدورة حياة `status` وحقول `pipeline.*`.

### الإعداد

1. **خطة Blaze**: الدوال السحابية (`functions/`) تحتاج اتصالًا صادرًا (لاستدعاء
   Azure DevOps)، وهذا يتطلب خطة Blaze مدفوعة حسب الاستخدام.
2. **إعدادات الدالة السحابية** داخل `functions/`:
   - انسخ `functions/.env.example` إلى `functions/.env` واملأ `AZDO_ORG` و
     `AZDO_PROJECT` و`AZDO_PIPELINE_ID` (ليست أسرارًا لكنها خاصة بالمشروع).
   - اضبط رمز الوصول الشخصي (PAT) من Azure DevOps كسر:
     `firebase functions:secrets:set AZDO_PAT` (الصلاحية: **Build: Read & execute**).
   - انشر: `cd functions && npm install && firebase deploy --only functions`.
   - **إن فشل النشر بخطأ بناء أو صلاحيات**: بعض المشاريع لم تعد تمنح أدوار IAM
     تلقائيًا لحساب الخدمة الافتراضي. امنح
     `{project-number}-compute@developer.gserviceaccount.com` (Console ← IAM)
     أدوار **Cloud Build Service Account** و**Artifact Registry Writer**
     و**Cloud Datastore User**، ثم أعد النشر.
3. **Pipeline في Azure DevOps**: أنشئه من `pipeline/azure-pipelines.yml` (راجع
   أدناه إبقاء `pipeline/` هنا أو نقله لمستودع Azure Repos منفصل)، وهو بـ
   `trigger: none` و`pr: none` فلا يعمل إلا عبر REST API.
   - **ملف آمن (Secure file)**: ارفع مفتاح حساب خدمة Firebase بصيغة JSON باسم
     `firebase-service-account.json` (Pipelines ← Library ← Secure files)،
     وامنحه صلاحيتي **Cloud Datastore User** و**Storage Object Viewer** في IAM.
   - **مجموعة متغيرات (Variable group)**: أنشئ `swift-app-pipeline` وفيها
     `FIREBASE_STORAGE_BUCKET`.
   - **أول تشغيل يدوي**: شغّل الـ pipeline يدويًا مرة (Run pipeline بأي
     `requestId`) حتى يوافق Azure DevOps على استخدامه للملف الآمن ومجموعة
     المتغيرات؛ التشغيلات اللاحقة عبر REST تمرّ دون موافقة.
4. دوّن معرّف الـ pipeline (من رابطه أو `az pipelines list`) لاستخدامه في
   `AZDO_PIPELINE_ID` بالخطوة 2.

### مكان `pipeline/`

يعيش `pipeline/` في هذا المستودع افتراضيًا. لنقله إلى مستودع Azure Repos منفصل:
انسخ `pipeline/azure-pipelines.yml` و`pipeline/scripts/` إلى هناك، ووجّه مسار
YAML في إعداد الـ pipeline إلى الموقع الجديد، وحدّث `AZDO_PIPELINE_ID` إن أُعيد
إنشاء الـ pipeline.

## التخزين

البيانات **في الذاكرة فقط** وتضيع عند إعادة تحميل الصفحة. الواجهة `ConfigRepository`
هي نقطة الربط مع أي خدمة خلفية حقيقية (Firebase أو API أو Azure)؛ ويوجد
`RemoteConfigRepository` كهيكل جاهز غير منفّذ.

## النشر

كل دفع إلى `main` يشغّل `.github/workflows/deploy.yml`: تحليل ← اختبارات ← بناء الويب ← نشر على GitHub Pages.
التطبيق يستخدم روابط بـ `#` فتعمل الروابط العميقة وتحديث الصفحة على Pages.

## القيود الحالية

- تخزين المسودات والإصدارات في الأداة نفسها في الذاكرة فقط (انظر "التخزين"
  أدناه)؛ Firebase يتولى الطلبات المُرسَلة، ويُطلِق خط Azure DevOps لكل طلب
  (انظر "خط البناء" أعلاه) — لكنه يتوقف عند توفّر بيانات الطلب وأصوله لديه، فلا
  يوجد بعد مولّد تطبيق ولا بناء للمتاجر. راجع
  [`docs/PHASE2_PROGRESS.md`](docs/PHASE2_PROGRESS.md) (بالإنجليزية) لحالة خط
  البناء الحالية والنقاط المتعارضة والخطوات التالية.
- بيانات العميل: الاسم والبريد والهاتف فقط، دون قائمة عملاء.
- ملف JSON المستورد لا يحمل الصور، فيجب رفع الشعار والأيقونة من جديد.
- استخراج الألوان يعمل مع شعارات PNG فقط (لا يعمل مع SVG).

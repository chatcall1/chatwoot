# تثبيت الفورك على سيرفر جديد

هذا المسار ينشئ نسخة جديدة بقاعدة بيانات فارغة، ويشمل المحادثات الداخلية وبناء
التدفقات وحملات واتساب ومحرر القوالب وواجهة نافذة الرد واستئناف المحادثة.
تبقى المحادثات الداخلية وبناء التدفقات معطّلتين للحساب الجديد حتى يفعّلهما السوبر أدمن.

## المتطلبات

- سيرفر Linux عليه Git وBash وOpenSSL وDocker Engine وDocker Compose v2.
- نطاق مربوط بالسيرفر، ووكيل عكسي يدعم HTTPS وWebSocket.
- ذاكرة كافية لبناء الواجهة؛ يوصى بذاكرة 8 GB أثناء البناء.
- إعدادات SMTP لإرسال الدعوات ورسائل استعادة كلمة المرور والبريد.

## خطوات التثبيت

```bash
git clone --branch feat/internal-chat --single-branch https://github.com/chatcall1/chatwoot.git
cd chatwoot
bin/setup-production-env https://support.example.com
```

استبدل النطاق التجريبي بنطاقك الحقيقي. الأمر ينشئ ملف `.env` بمفاتيح مستقلة للجلسات
والتشفير وقاعدة البيانات وRedis، ويرفض الكتابة فوق ملف موجود. احتفظ بهذه المفاتيح
ولا تغيّرها بعد التثبيت.

عدّل إعدادات البريد في `.env`، خصوصًا `MAILER_SENDER_EMAIL` و`SMTP_ADDRESS`
و`SMTP_PORT` و`SMTP_USERNAME` و`SMTP_PASSWORD` وإعدادات المصادقة وTLS حسب مزوّدك.
باقي المتغيرات موضحة في `.env.example` ويمكن إعداد التكاملات لاحقًا.

```bash
docker compose -f docker-compose.production.yaml up -d --build
docker compose -f docker-compose.production.yaml ps -a
docker compose -f docker-compose.production.yaml logs --tail=100 prepare rails sidekiq
```

يبني الأمر صورة Docker من كود هذا الفرع، وينتظر PostgreSQL وRedis، ثم ينشئ قاعدة
البيانات وإعدادات التثبيت قبل تشغيل التطبيق والمهام الخلفية. انتهاء خدمة `prepare`
برمز `0` طبيعي ومطلوب؛ بقية الخدمات يجب أن تبقى قيد التشغيل. لا تحتاج إلى أوامر SQL
يدوية لإنشاء جداول الإضافات أو دالة البحث.

اضبط الوكيل العكسي ليوجّه النطاق إلى `127.0.0.1:3000` مع تمرير `Host`
و`X-Forwarded-Proto: https` ودعم ترقية WebSocket لمسار `/cable`.
يمكن تغيير المنفذ المحلي بإضافة `CHATWOOT_PORT=3001` إلى `.env`.

افتح `https://support.example.com/installation/onboarding` وأنشئ أول حساب والسوبر
أدمن. بعدها افتح `/super_admin` وعدّل الحساب المطلوب وفعّل **Internal Chat**
و/أو **Flow Builder**. لا تتفعّل الميزتان لباقي الحسابات تلقائيًا.

واتساب يحتاج ربط صندوق الوارد الخاص بك واعتماد قوالبه. Captain وبقية التكاملات
تحتاج مفاتيحها وتراخيصها عند انطباقها؛ هذه إعدادات تشغيل وليست تعديلات على الكود.

استخدم ملف الإنتاج والأوامر أعلاه لهذا الفورك. صور `chatwoot/chatwoot` الجاهزة
وسكربتات التثبيت الأصلية تنزّل النسخة الأصلية ولا تبني تخصيصات هذا الفرع.

## التحقق والتحديث

تحقق من أن `/health` يعيد `{"status":"woot"}`، وأن الواجهة تعمل، وأن السوبر أدمن
يستطيع تفعيل الإضافات للحساب المطلوب، وأن خدمة `sidekiq` تعمل.

للتحديث، احتفظ بنفس المجلد وملف `.env` ووحدات التخزين، ثم نفّذ:

```bash
git pull --ff-only origin feat/internal-chat
docker compose -f docker-compose.production.yaml build
docker compose -f docker-compose.production.yaml stop rails sidekiq
docker compose -f docker-compose.production.yaml run --rm prepare
docker compose -f docker-compose.production.yaml up -d
```

إذا فشل تجهيز قاعدة البيانات، عالج الخطأ قبل إعادة تشغيل التطبيق. لا تحذف وحدات التخزين.

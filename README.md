# 🛡️ نظام أوامر هواللي — Hawalli Sheets Command Agent

نظام متكامل لإدارة حضور الموظفين والنوبات وكشوفات الحجز عبر أوامر عربية طبيعية متصلة بـ Google Sheets.

---

## 1. فكرة النظام

يتيح النظام كتابة أوامر باللغة العربية بشكل طبيعي مثل:

```
سجل أحمد محمد في نوبة الصباح اليوم
أضف سعود الحمدان إلى نوبة الليل بتاريخ 26/4/2026
عدل حالة فهد إلى حاضر
ابحث عن الموظف عبدالله الشمري
سو كشف نهاية اليوم
انقل كل الموجودين في نوبة الليل إلى كشف الحجز لليوم التالي
```

ثم يقوم النظام بـ:
1. تحليل الأمر وتحويله إلى إجراء محدد
2. عرض معاينة للإجراء
3. تنفيذه على Google Sheets أو إرساله للاعتماد في الحالات الحساسة

---

## 2. المتطلبات

- Node.js 18 أو أحدث
- حساب Google (لإنشاء Service Account)
- Google Spreadsheet مُشارَك مع Service Account

---

## 3. إنشاء Google Service Account

1. افتح [Google Cloud Console](https://console.cloud.google.com/)
2. أنشئ مشروعاً جديداً أو استخدم مشروعاً موجوداً
3. فعّل **Google Sheets API**:
   - من القائمة الجانبية → APIs & Services → Library
   - ابحث عن "Google Sheets API" وفعّله
4. أنشئ Service Account:
   - من القائمة → APIs & Services → Credentials
   - Create Credentials → Service Account
   - أدخل اسماً للـ Service Account واضغط Create
   - اختر دور "Editor" أو "Owner" واضغط Continue ثم Done
5. أنشئ مفتاحاً (Key):
   - انقر على Service Account الذي أنشأته
   - انتقل إلى تبويب Keys
   - Add Key → Create New Key → JSON
   - سيُنزَّل ملف JSON — **احتفظ به بأمان**

---

## 4. مشاركة Google Sheet مع Service Account

1. افتح Google Sheet المطلوب (أو أنشئ واحداً جديداً)
2. انسخ رابط الـ Spreadsheet وخذ منه الـ ID:
   ```
   https://docs.google.com/spreadsheets/d/[SPREADSHEET_ID]/edit
   ```
3. من أيقونة المشاركة (Share):
   - أضف بريد الـ Service Account (الشكل: `name@project.iam.gserviceaccount.com`)
   - امنحه دور **Editor**
   - اضغط Send

> ⚠️ إذا لم تُشارك الـ Sheet مع Service Account فلن يتمكن النظام من القراءة أو الكتابة.

---

## 5. إعداد ملف .env

انسخ الملف:

```bash
cp .env.example .env
```

ثم عدّل القيم:

```env
PORT=3000

# من رابط Google Sheet
SPREADSHEET_ID=1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms

# من ملف JSON الذي نزّلته
GOOGLE_CLIENT_EMAIL=my-agent@my-project.iam.gserviceaccount.com
GOOGLE_PRIVATE_KEY="-----BEGIN RSA PRIVATE KEY-----\nMIIEow...\n-----END RSA PRIVATE KEY-----"

# رمز سري قوي لحماية API
ADMIN_TOKEN=your_strong_random_token_here

# true = يطلب اعتماد قبل الأوامر الحساسة
APPROVAL_MODE=true

TIMEZONE=Asia/Kuwait
```

> ⚠️ **تنبيه:** المفتاح الخاص يحتوي على `\n` كنص — هذا صحيح. النظام يحوّلها تلقائياً إلى أسطر جديدة.

لإنشاء `ADMIN_TOKEN` آمن:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

---

## 6. التشغيل

```bash
# تثبيت الحزم
npm install

# تشغيل بوضع التطوير (مع إعادة التشغيل التلقائي)
npm run dev

# تشغيل في الإنتاج
npm start
```

---

## 7. فتح النظام

بعد التشغيل، افتح المتصفح على:

```
http://localhost:3000
```

---

## 8. تجهيز جداول Google Sheets

في أول تشغيل، نفّذ الأمر التالي لإنشاء جميع الجداول والعناوين تلقائياً:

```bash
curl -X POST http://localhost:3000/api/setup \
  -H "x-admin-token: YOUR_TOKEN"
```

أو من واجهة النظام اكتب: `جهز الشيتات`

---

## 9. أمثلة أوامر عربية

### تسجيل حضور

```
سجل أحمد محمد في نوبة الصباح اليوم
أضف سعود الحمدان إلى نوبة الليل بتاريخ 26/4/2026
حط فهد العتيبي بنوبة العصر حاضر
```

### تعديل سجل

```
عدل حالة محمد إلى غائب
خله فهد حاضر في نوبة الصباح اليوم
```

### بحث عن موظف

```
دور عبدالله الشمري
ابحث عن خالد
```

### عرض الحضور

```
طلع كشف اليوم
اعرض نوبة الليل اليوم
```

### النواقص

```
شوفلي نواقص الليل
اعرض النواقص في نوبة العصر
```

### نقل نوبة الليل للحجز

```
انقل كل الموجودين في نوبة الليل إلى كشف الحجز لليوم التالي
```

### التقرير اليومي

```
سو كشف نهاية اليوم
جهز تقرير يومي مختصر
طلع كشف اليوم
```

### ملاحظات

```
أضف ملاحظة على محمد: تم التواصل معه
حط ملاحظة على سعود: يراجع القيادة
```

### حذف سجل

```
احذف السجل رقم 15 بعد الاعتماد
```

---

## 10. طريقة الاعتماد والرفض

الأوامر الحساسة (الحذف، النقل الجماعي، التقارير) تُرسل للاعتماد أولاً.

### من الواجهة:
- ستظهر في قسم "الاعتمادات المعلقة"
- اضغط ✅ اعتماد أو ❌ رفض

### من API:

```bash
# عرض الاعتمادات المعلقة
curl http://localhost:3000/api/approvals \
  -H "x-admin-token: YOUR_TOKEN"

# اعتماد أمر
curl -X POST http://localhost:3000/api/approve/APPROVAL_ID \
  -H "x-admin-token: YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user":"مشرف"}'

# رفض أمر
curl -X POST http://localhost:3000/api/reject/APPROVAL_ID \
  -H "x-admin-token: YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"user":"مشرف","reason":"بيانات خاطئة"}'
```

---

## 11. اختبار بـ curl

```bash
# فحص صحة النظام
curl http://localhost:3000/health

# إرسال أمر
curl -X POST http://localhost:3000/api/command \
  -H "Content-Type: application/json" \
  -H "x-admin-token: YOUR_TOKEN" \
  -d '{"text":"سجل أحمد محمد في نوبة الصباح اليوم","user":"مشرف"}'

# بحث موظف
curl "http://localhost:3000/api/employees/search?q=أحمد" \
  -H "x-admin-token: YOUR_TOKEN"

# حضور اليوم
curl http://localhost:3000/api/today \
  -H "x-admin-token: YOUR_TOKEN"

# سجل الأوامر
curl http://localhost:3000/api/logs \
  -H "x-admin-token: YOUR_TOKEN"
```

---

## 12. ملاحظات الأمان

| الإجراء | التفاصيل |
|---------|----------|
| **Token حماية** | جميع نقاط API تتطلب `x-admin-token` |
| **لا كلمات مرور** | يستخدم Service Account فقط |
| **وضع الاعتماد** | الأوامر الحساسة لا تُنفَّذ دون موافقة |
| **سجل كامل** | كل أمر يُسجَّل محلياً وعلى Sheets |
| **XSS Protection** | جميع المدخلات تُهرَّب في الواجهة |
| **Zod Validation** | جميع البيانات الواردة تُتحقق منها |
| **لا أسرار مضمّنة** | جميع البيانات الحساسة في .env |

---

## 13. هيكل ملفات المشروع

```
/src
  /config
    env.js              - إعدادات البيئة والتحقق منها
    googleSheets.js     - الاتصال بـ Google Sheets API
  /controllers
    commandController.js
    approvalController.js
    employeeController.js
    reportController.js
  /services
    arabicCommandParser.js  - محلل الأوامر العربية (قاعدة معرفة)
    sheetsService.js        - عمليات CRUD على Google Sheets
    commandProcessor.js     - منسق تنفيذ الأوامر
    approvalService.js      - إدارة الاعتمادات المعلقة
    logService.js           - تسجيل العمليات
  /routes
    commandRoutes.js
    approvalRoutes.js
    employeeRoutes.js
    setupRoutes.js
    reportRoutes.js
  /utils
    dateUtils.js        - معالجة التواريخ بمنطقة Kuwait
    arabicNormalizer.js - تطبيع النص العربي وتحليله
    idGenerator.js      - توليد معرّفات فريدة
  /schemas
    actionSchemas.js    - مخططات Zod لجميع الإجراءات
/public
  index.html            - واجهة المستخدم (RTL عربي)
  style.css             - التصميم
  app.js                - JavaScript الواجهة
/data
  pendingApprovals.json - (يُنشأ تلقائياً) اعتمادات معلقة
  commandLogs.json      - (يُنشأ تلقائياً) سجل محلي للأوامر
server.js               - نقطة دخول Express
.env.example            - قالب متغيرات البيئة
```

---

## 14. جداول Google Sheets المطلوبة

| اسم الجدول | الوصف |
|-----------|-------|
| `الموظفين` | بيانات الموظفين الأساسية |
| `الحضور_اليومي` | سجلات الحضور اليومية |
| `كشف_الحجز` | موظفو الحجز (المنقولون من الليل) |
| `النواقص` | العجز في الأعداد لكل نوبة |
| `التقارير_اليومية` | ملخصات اليوم |
| `سجل_الأوامر` | تاريخ جميع الأوامر المنفذة |
| `الاعتمادات_المعلقة` | الأوامر التي تنتظر اعتماد |

---

## 15. الرفع على الإنترنت

### على Render.com

1. ارفع المشروع على GitHub
2. أنشئ New Web Service على Render
3. اختر الـ Repository
4. ضع في Start Command: `npm start`
5. أضف جميع متغيرات .env في قسم Environment Variables

### على Railway.app

1. من الموقع، أنشئ مشروعاً جديداً
2. Deploy from GitHub
3. أضف متغيرات البيئة
4. الرفع يصير تلقائياً

---

## 16. الربط مع واتساب أو تليجرام (مستقبلاً)

### تليجرام:
1. أنشئ بوتاً عبر [BotFather](https://t.me/botfather)
2. استخدم مكتبة `node-telegram-bot-api`
3. عند وصول رسالة، أرسلها كـ POST إلى `/api/command`
4. أرسل الرد للمستخدم

### واتساب (عبر Twilio أو WhatsApp Cloud API):
1. اشترك في Twilio Sandbox for WhatsApp
2. اضبط الـ Webhook ليشير إلى `/api/command`
3. النظام يستقبل الأمر وينفذه ويرد

---

## 17. إضافة محلل ذكاء اصطناعي (مستقبلاً)

المحلل مبني بنظام Plugin:

```javascript
// في server.js
const { setAIParser } = require('./src/services/arabicCommandParser');

setAIParser(async (text) => {
  // استدعاء Claude API أو GPT
  const response = await anthropic.messages.create({
    model: 'claude-sonnet-4-6',
    messages: [{ role: 'user', content: `حوّل هذا الأمر العربي إلى JSON: ${text}` }],
  });
  return JSON.parse(response.content[0].text);
});
```

---

## مطوّر النظام

بُني بواسطة Claude (Anthropic) — نظام متكامل للمشاريع الميدانية.

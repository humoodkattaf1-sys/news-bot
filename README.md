# بوت الأخبار

يجمع الأخبار من RSS ويرسل كل خبر **كبطاقة مصممة 1080×1080** إلى قناتك في تلقرام، مع زر "اقرأ الخبر كامل" وسطر للراعي.
البطاقات تنحفظ في مجلد `cards/`، وتقدر تنشرها بعد على إنستقرام وتيك توك.

## التشغيل
```bash
pip install -r requirements.txt
cp .env.example .env   # وعبّي القيم
python main.py
```

## خطوات الربح
1. سوّ قناة تلقرام عامة وخلّ البوت أدمن فيها، وحط `CHAT_ID=@اسم_القناة`.
2. انشر البطاقات من `cards/` على إنستقرام وتيك توك وحط رابط القناة في البايو.
3. لما توصل تقريباً ١٠٠٠ إلى ٢٠٠٠ مشترك، بع خانة الراعي (`SPONSOR_TEXT`) لمتجر أو تطبيق محلي بمبلغ أسبوعي أو شهري.
4. المرحلة الجاية: قناة VIP مدفوعة فيها تنبيهات أسرع ومجالات مخصصة (Supabase).

## النشر التلقائي على إنستقرام
البوت يرفع البطاقة لإنستقرام بنفسه، بس **بحدود**: افتراضياً ٨ منشورات باليوم كحد أقصى، وساعة على الأقل بين كل منشور وثاني (تغيّرها من `IG_MAX_PER_DAY` و`IG_MIN_GAP_MINUTES`). النشر الكثير يخلّي إنستقرام يحظر الحساب أو يقلل وصوله. الأخبار اللي تزيد عن الحد تنزل في تلقرام بس.

### التجهيز (مرة وحدة)
1. **حوّل حساب إنستقرام لحساب احترافي** (Business أو Creator)، واربطه بصفحة فيسبوك.
2. ادخل [developers.facebook.com](https://developers.facebook.com) وسوّ تطبيق (App) من نوع Business، وأضف له منتج **Instagram**.
3. من **Graph API Explorer** طلّع توكن فيه هذي الصلاحيات:
   `instagram_basic`, `instagram_content_publish`, `pages_show_list`, `pages_read_engagement`.
   بعدين حوّله لتوكن طويل المدة (Long-lived) من أداة Access Token Debugger.
4. اعرف رقم حسابك في إنستقرام: نفّذ `me/accounts?fields=instagram_business_account` في Graph API Explorer، وانسخ الـ `id` اللي داخل `instagram_business_account`. هذا هو `IG_USER_ID`.
5. **Supabase:** شغّل مشروعك (Restore)، وخذ من Settings → API قيمة `Project URL` و`service_role key`. البوت يسوي الـ bucket بنفسه.
6. حط القيم كلها في `.env`.

> التوكن الطويل يخلص بعد ٦٠ يوم تقريباً. إذا طلع لك خطأ `190`، جدّد التوكن.

## التشغيل على GitHub Actions (بدون كمبيوتر، مجاني)
البوت يشتغل بنفسه كل ١٥ دقيقة من ملف `.github/workflows/bot.yml`، ويحفظ الأخبار اللي أرسلها في Supabase.

من الريبو في GitHub: **Settings ← Secrets and variables ← Actions**
- تبويب **Secrets** (أي شي سري):
  - `TELEGRAM_TOKEN`
  - `SUPABASE_SERVICE_KEY`
  - `IG_ACCESS_TOKEN` (اختياري)
- تبويب **Variables** (أي شي عادي):
  - `CHAT_ID`
  - `BRAND`
  - `SPONSOR_TEXT` و`IG_USER_ID` (اختياري)

بعدها افتح تبويب **Actions ← News Bot ← Run workflow** عشان تجربه على طول.

## تغيير المصادر
كل المصادر موجودة في ملف `feeds.json`، وتقدر تعدّله من الجوال من هنا:
https://github.com/humoodkattaf1-sys/news-bot/edit/main/feeds.json

كل مصدر سطر واحد بهالشكل:
```json
{"name": "💻 اسم المصدر", "badge": "تقنية", "color": "#8b5cf6", "url": "رابط RSS"},
```
- `badge`: الكلمة اللي تطلع فوق البطاقة (عاجل، ترند، تقنية، رياضة...).
- `color`: لون البطاقة.
- آخر سطر في الملف ما يكون بعده فاصلة `,`.

البوت يخلط المصادر مع بعض، وينشر بحد أقصى ٦ منشورات بكل تشغيلة. تقدر تغيّر العدد من متغير `MAX_PER_RUN`.

## الترجمة والتلخيص بالعربي (Claude)
إذا حطيت `ANTHROPIC_API_KEY` في Secrets، Claude يسوي ثلاث أشياء:
- يختار الأخبار اللي تهم المصممين وصنّاع المحتوى، ويستبعد الباقي.
- يكتب لكل خبر عنوان عربي.
- يضيف سطر 💡 "وش يفيدك" تحت كل خبر.

الموديل الافتراضي `claude-opus-5-5`. إذا تبي تكلفة أقل، أضف متغير `CLAUDE_MODEL` وحط قيمته `claude-haiku-5-5`.

وإذا ما فيه مفتاح، المصادر اللي عليها `"english": true` تتوقف، والمصادر العربية تكمل عادي.

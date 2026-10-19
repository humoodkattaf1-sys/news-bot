import html, json, os, re, sys, time
import feedparser, requests
from dotenv import load_dotenv
from card import make_card

load_dotenv()
# اللصق من الجوال أحياناً يضيف مسافات أو سطر فاضي بعد القيمة
for _k, _v in list(os.environ.items()):
    os.environ[_k] = _v.strip()
import store, instagram, writer  # بعد load_dotenv عشان يقرأون الإعدادات

# لو انلصقت رسالة BotFather كاملة، ناخذ التوكن منها بس
_token = re.search(r"\d{6,}:[A-Za-z0-9_-]{30,}", os.environ["TELEGRAM_TOKEN"])
TELEGRAM_TOKEN = _token.group(0) if _token else os.environ["TELEGRAM_TOKEN"]
CHAT_ID = os.environ["CHAT_ID"]                              # رقمك أو @اسم_القناة
BRAND = os.getenv("BRAND") or (CHAT_ID if CHAT_ID.startswith("@") else "")  # يطلع في أسفل كل بطاقة
INSTAGRAM = os.getenv("INSTAGRAM", "").lstrip("@")                # حساب إنستقرام يطلع رابطه تحت كل خبر
SPONSOR_TEXT = os.getenv("SPONSOR_TEXT", "")                  # سطر الراعي، فاضي = بدون راعي
SPONSOR_EVERY = int(os.getenv("SPONSOR_EVERY") or "5")        # يطلع الراعي كل كم خبر
INTERVAL = int(os.getenv("INTERVAL") or "900")
PER_FEED = int(os.getenv("PER_FEED") or "3")

API = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}"
CARDS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cards")

MAX_PER_RUN = int(os.getenv("MAX_PER_RUN") or "6")           # أقصى عدد منشورات بكل تشغيلة

ARABIC = re.compile(r"[\u0600-\u06FF]")

# المصادر في feeds.json: عدّله من GitHub عشان تضيف أو تشيل مصادر
with open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "feeds.json"), encoding="utf-8") as f:
    FEEDS = json.load(f)


def caption(source, title, count, why=""):
    text = f"{source}\n<b>{html.escape(title)}</b>"
    if why:
        text += f"\n\n💡 {html.escape(why)}"
    if INSTAGRAM:
        text += f'\n\n📸 <a href="https://instagram.com/{INSTAGRAM}">تابعنا على إنستقرام @{INSTAGRAM}</a>'
    elif BRAND:
        text += f"\n\n{BRAND}"
    if SPONSOR_TEXT and count % SPONSOR_EVERY == 0:
        text += f"\n\n📢 {SPONSOR_TEXT}"
    return text


def post(source, title, link, accent, count, badge="عاجل", why=""):
    path = os.path.join(CARDS_DIR, f"{int(time.time() * 1000)}.png")
    make_card(title, source.split(" ", 1)[-1], path, brand=BRAND, accent=accent, badge=badge)
    markup = json.dumps({"inline_keyboard": [[{"text": "اقرأ الخبر كامل", "url": link}]]})
    with open(path, "rb") as photo:
        r = requests.post(f"{API}/sendPhoto", timeout=30, files={"photo": photo},
                          data={"chat_id": CHAT_ID, "caption": caption(source, title, count, why),
                                "parse_mode": "HTML", "reply_markup": markup})
    if not r.ok:
        raise RuntimeError(f"Telegram {r.status_code}: {r.text[:300]}")

    if instagram.can_post():
        try:
            cta = f"t.me/{CHAT_ID.lstrip('@')}" if CHAT_ID.startswith("@") else ""
            instagram.post_story(path, cta=cta, accent=accent)
            print("انرفعت ستوري على إنستقرام")
        except Exception as err:
            print(f"فشل النشر على إنستقرام: {err}")


def new_items(sent):
    """يجمع الأخبار الجديدة من كل مصدر، ويخلطها بالتناوب عشان ما يطغى مصدر واحد."""
    per_feed = []
    for feed in FEEDS:
        if feed.get("english") and not writer.enabled:
            continue  # المصادر الإنجليزية تنتظر مفتاح Claude عشان تترجم
        parsed = feedparser.parse(feed["url"])
        if not parsed.entries:
            print(f"ما وصلت أخبار من {feed['name']} (تأكد من الرابط)")
        items = []
        for e in parsed.entries[:PER_FEED * 3]:
            eid = e.get("id", e.get("link", ""))
            title, link = e.get("title", "").strip(), e.get("link", "")
            if not eid or eid in sent or not title:
                continue
            # ترندات قوقل: العنوان كلمة بحث بس، فنضيف عنوان الخبر المرتبط فيها
            if e.get("ht_news_item_title"):
                title = f"{title}: {e['ht_news_item_title']}"
                link = e.get("ht_news_item_url") or link
            # مثل Product Hunt: العنوان اسم بس، فنضيف الوصف
            if feed.get("with_summary") and e.get("summary"):
                summary = re.sub(r"<[^>]+>", " ", html.unescape(e["summary"]))
                summary = re.sub(r"\bDiscussion\s*\|\s*Link\b", "", summary)
                title = f"{title}: {' '.join(summary.split())[:120]}"
            if feed.get("arabic_only") and not ARABIC.search(title):
                continue
            summary = " ".join(re.sub(r"<[^>]+>", " ", html.unescape(e.get("summary", ""))).split())[:300]
            items.append({"feed": feed, "eid": eid, "title": title, "link": link, "summary": summary})
            if len(items) >= PER_FEED:
                break
        per_feed.append(items)
    mixed = []
    while any(per_feed):
        for items in per_feed:
            if items:
                mixed.append(items.pop(0))
    return mixed


def run_once(sent):
    sent_now, failed = 0, 0
    # نعطي Claude ضعف العدد عشان يختار الأفضل
    items, rejected = writer.rewrite(new_items(sent)[:MAX_PER_RUN * 3])
    for it in rejected:
        store.mark_sent(sent, it["eid"])  # عشان ما ينعرض على Claude مرة ثانية
    if rejected:
        print(f"Claude استبعد {len(rejected)} خبر ما يناسب القناة")
    for it in items[:MAX_PER_RUN]:
        feed, title = it["feed"], it["title"]
        source = feed["name"]
        try:
            post(source, title, it["link"], feed.get("color", "#ef4444"), len(sent) + 1,
                 badge=feed.get("badge", "عاجل"), why=it.get("why", ""))
            store.mark_sent(sent, it["eid"])
            sent_now += 1
            print(f"انرسل: {source} | {title[:60]}")
            time.sleep(2)
        except Exception as err:
            failed += 1
            print(f"فشل إرسال خبر من {source}: {err}")
    return sent_now, failed

if __name__ == "__main__":
    os.makedirs(CARDS_DIR, exist_ok=True)
    if instagram.enabled:
        try:
            instagram.setup()
        except Exception as err:
            print(f"إنستقرام ما اشتغل، بنكمل تلقرام بس: {err}")
    me = requests.get(f"{API}/getMe", timeout=30)
    if not me.ok:
        print(f"التوكن مرفوض من تلقرام ({me.status_code}). "
              f"شكل التوكن {'صح' if _token else 'غلط'}: لازم يكون مثل 123456789:AAE...")
        sys.exit(1)
    print(f"البوت شغال: @{me.json()['result']['username']}")
    sent = store.load_sent()
    # --once: يشتغل مرة وحدة ويطلع (لـ GitHub Actions)
    if "--once" in sys.argv:
        sent_now, failed = run_once(sent)
        print(f"انرسل {sent_now} خبر، وفشل {failed}")
        if failed and not sent_now:
            sys.exit(1)  # عشان يطلع أحمر في GitHub وتنتبه
    else:
        while True:
            run_once(sent)
            time.sleep(INTERVAL)

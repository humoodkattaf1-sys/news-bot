import html, json, os, sys, time
import feedparser, requests
from dotenv import load_dotenv
from card import make_card

load_dotenv()
# اللصق من الجوال أحياناً يضيف مسافات أو سطر فاضي بعد القيمة
for _k, _v in list(os.environ.items()):
    os.environ[_k] = _v.strip()
import store, instagram  # بعد load_dotenv عشان يقرأون الإعدادات

TELEGRAM_TOKEN = os.environ["TELEGRAM_TOKEN"]
CHAT_ID = os.environ["CHAT_ID"]                              # رقمك أو @اسم_القناة
BRAND = os.getenv("BRAND") or (CHAT_ID if CHAT_ID.startswith("@") else "")  # يطلع في أسفل كل بطاقة
SPONSOR_TEXT = os.getenv("SPONSOR_TEXT", "")                  # سطر الراعي، فاضي = بدون راعي
SPONSOR_EVERY = int(os.getenv("SPONSOR_EVERY") or "5")        # يطلع الراعي كل كم خبر
INTERVAL = int(os.getenv("INTERVAL") or "900")
PER_FEED = int(os.getenv("PER_FEED") or "3")

API = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}"
CARDS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "cards")

# (الاسم، الرابط، لون البطاقة)
RSS_FEEDS = [
    ("🔴 الجزيرة", "https://www.aljazeera.net/aljazeerarss/a2c31171-d8d4-4d8c-a488-ff9afb9f8a3d/66c43a4960f84d888f6a20f6", "#d97706"),
    ("🔵 BBC عربي", "https://feeds.bbci.co.uk/arabic/rss.xml", "#b91c1c"),
    ("🟢 فرانس 24", "https://www.france24.com/ar/rss", "#0ea5e9"),
    ("📡 CNN", "http://rss.cnn.com/rss/edition.rss", "#dc2626"),
]


def caption(source, title, count):
    text = f"{source}\n<b>{html.escape(title)}</b>"
    if BRAND:
        text += f"\n\n{BRAND}"
    if SPONSOR_TEXT and count % SPONSOR_EVERY == 0:
        text += f"\n\n📢 {SPONSOR_TEXT}"
    return text


def post(source, title, link, accent, count):
    path = os.path.join(CARDS_DIR, f"{int(time.time() * 1000)}.png")
    make_card(title, source.split(" ", 1)[-1], path, brand=BRAND, accent=accent)
    markup = json.dumps({"inline_keyboard": [[{"text": "اقرأ الخبر كامل", "url": link}]]})
    with open(path, "rb") as photo:
        r = requests.post(f"{API}/sendPhoto", timeout=30, files={"photo": photo},
                          data={"chat_id": CHAT_ID, "caption": caption(source, title, count),
                                "parse_mode": "HTML", "reply_markup": markup})
    if not r.ok:
        raise RuntimeError(f"Telegram {r.status_code}: {r.text[:300]}")

    if instagram.can_post():
        try:
            instagram.post(path, source.split(" ", 1)[-1], title, brand=BRAND)
        except Exception as err:
            print(f"فشل النشر على إنستقرام: {err}")


def run_once(sent):
    sent_now, failed = 0, 0
    for source, url, accent in RSS_FEEDS:
        feed = feedparser.parse(url)
        if not feed.entries:
            print(f"ما وصلت أخبار من {source}")
        for e in feed.entries[:PER_FEED]:
            eid = e.get("id", e.get("link", ""))
            if not eid or eid in sent:
                continue
            try:
                post(source, e.get("title", "").strip(), e.get("link", ""), accent, len(sent) + 1)
                store.mark_sent(sent, eid)
                sent_now += 1
                print(f"انرسل: {source} | {e.get('title', '')[:60]}")
                time.sleep(2)
            except Exception as err:
                failed += 1
                print(f"فشل إرسال خبر من {source}: {err}")
    return sent_now, failed


if __name__ == "__main__":
    os.makedirs(CARDS_DIR, exist_ok=True)
    if instagram.enabled:
        instagram.ensure_bucket()
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

import html, json, os, time
import feedparser, requests
from dotenv import load_dotenv
from card import make_card

load_dotenv()

TELEGRAM_TOKEN = os.environ["TELEGRAM_TOKEN"]
CHAT_ID = os.environ["CHAT_ID"]                      # رقمك أو @اسم_القناة
BRAND = os.getenv("BRAND", "")                        # يطلع في أسفل كل بطاقة
SPONSOR_TEXT = os.getenv("SPONSOR_TEXT", "")          # سطر الراعي، فاضي = بدون راعي
SPONSOR_EVERY = int(os.getenv("SPONSOR_EVERY", "5"))  # يطلع الراعي كل كم خبر
INTERVAL = int(os.getenv("INTERVAL", "900"))
PER_FEED = int(os.getenv("PER_FEED", "3"))

API = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}"
BASE = os.path.dirname(os.path.abspath(__file__))
SENT_FILE = os.path.join(BASE, "sent.json")
CARDS_DIR = os.path.join(BASE, "cards")

# (الاسم، الرابط، لون البطاقة)
RSS_FEEDS = [
    ("🔴 الجزيرة", "https://www.aljazeera.net/aljazeerarss/a2c31171-d8d4-4d8c-a488-ff9afb9f8a3d/66c43a4960f84d888f6a20f6", "#d97706"),
    ("🔵 BBC عربي", "https://feeds.bbci.co.uk/arabic/rss.xml", "#b91c1c"),
    ("🟢 فرانس 24", "https://www.france24.com/ar/rss", "#0ea5e9"),
    ("📡 CNN", "http://rss.cnn.com/rss/edition.rss", "#dc2626"),
]


def load_sent():
    try:
        with open(SENT_FILE) as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return []


def save_sent(sent):
    with open(SENT_FILE, "w") as f:
        json.dump(sent[-2000:], f)


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
    r.raise_for_status()


def run_once(sent, count):
    for source, url, accent in RSS_FEEDS:
        feed = feedparser.parse(url)
        for e in feed.entries[:PER_FEED]:
            eid = e.get("id", e.get("link", ""))
            if not eid or eid in sent:
                continue
            try:
                count += 1
                post(source, e.get("title", "").strip(), e.get("link", ""), accent, count)
                sent.append(eid)
                save_sent(sent)
                time.sleep(2)
            except Exception as err:
                print(f"فشل إرسال خبر من {source}: {err}")
    return count


if __name__ == "__main__":
    os.makedirs(CARDS_DIR, exist_ok=True)
    sent, count = load_sent(), 0
    while True:
        count = run_once(sent, count)
        time.sleep(INTERVAL)

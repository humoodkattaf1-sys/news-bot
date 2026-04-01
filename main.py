import feedparser, requests, time

TELEGRAM_TOKEN = "7668498546:AAEXaOjiQqW7jHucqi2b2Q7lbW1tCL0XAHE"
CHAT_ID = "6567568546"

RSS_FEEDS = {
    "🔴 الجزيرة": "https://www.aljazeera.net/aljazeerarss/a2c31171-d8d4-4d8c-a488-ff9afb9f8a3d/66c43a4960f84d888f6a20f6",
    "🔵 BBC عربي": "https://feeds.bbci.co.uk/arabic/rss.xml",
    "🌍 Reuters": "https://feeds.reuters.com/reuters/topNews",
    "📡 CNN": "https://rss.cnn.com/rss/edition.rss",
}

sent = set()

def send(msg):
    requests.post(f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage",
                  data={"chat_id": CHAT_ID, "text": msg, "parse_mode": "HTML"})

while True:
    for name, url in RSS_FEEDS.items():
        try:
            feed = feedparser.parse(url)
            for e in feed.entries[:3]:
                eid = e.get("id", e.get("link",""))
                if eid not in sent:
                    send(f"{name}\n<b>{e.get('title','')}</b>\n{e.get('link','')}")
                    sent.add(eid)
                    time.sleep(1)
        except: pass
    time.sleep(900)

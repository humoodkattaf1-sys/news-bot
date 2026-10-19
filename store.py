"""يحفظ حالة البوت (الأخبار المرسلة ومنشورات إنستقرام) في Supabase.

لازم الحالة تكون برا البوت لأنه على GitHub Actions يشتغل من جديد كل مرة.
إذا Supabase مو مضبوط، يحفظ في ملف محلي.
"""
import json, os
from datetime import datetime, timedelta, timezone
import requests

SUPABASE_URL = os.getenv("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")
enabled = bool(SUPABASE_URL and SUPABASE_KEY)

SENT_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sent.json")
REST = f"{SUPABASE_URL}/rest/v1"


def headers(**extra):
    h = {"apikey": SUPABASE_KEY, **extra}
    # المفاتيح الجديدة (sb_secret_...) مو JWT، فتنرسل في apikey بس
    if not SUPABASE_KEY.startswith("sb_"):
        h["Authorization"] = f"Bearer {SUPABASE_KEY}"
    return h


def _get(table, **params):
    r = requests.get(f"{REST}/{table}", params=params, headers=headers(), timeout=30)
    r.raise_for_status()
    return r.json()


def _insert(table, row, **extra):
    r = requests.post(f"{REST}/{table}", json=row, timeout=30,
                      headers=headers(**{"Prefer": "return=minimal", **extra}))
    r.raise_for_status()


def load_sent():
    if enabled:
        return {row["id"] for row in _get("sent_items", select="id", order="created_at.desc", limit=2000)}
    try:
        with open(SENT_FILE) as f:
            return set(json.load(f))
    except (FileNotFoundError, json.JSONDecodeError):
        return set()


def mark_sent(sent, eid):
    sent.add(eid)
    if enabled:
        _insert("sent_items", {"id": eid}, Prefer="return=minimal,resolution=ignore-duplicates")
    else:
        with open(SENT_FILE, "w") as f:
            json.dump(list(sent)[-2000:], f)


def ig_posts_last_day():
    """أوقات منشورات إنستقرام في آخر ٢٤ ساعة، الأحدث أول."""
    if not enabled:
        return []
    since = (datetime.now(timezone.utc) - timedelta(days=1)).isoformat()
    rows = _get("ig_posts", select="posted_at", posted_at=f"gte.{since}", order="posted_at.desc")
    return [datetime.fromisoformat(r["posted_at"]) for r in rows]


def record_ig_post():
    _insert("ig_posts", {})

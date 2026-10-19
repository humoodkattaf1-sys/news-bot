"""نشر البطاقات على إنستقرام عن طريق Instagram Graph API.

إنستقرام ما يقبل رفع الصورة مباشرة، لازم تكون على رابط عام.
فنرفعها أول على Supabase Storage (bucket عام) وبعدين نعطي رابطها لإنستقرام.
"""
import os, time
import requests
from PIL import Image

IG_USER_ID = os.getenv("IG_USER_ID", "")
IG_TOKEN = os.getenv("IG_ACCESS_TOKEN", "")
GRAPH = f"https://graph.facebook.com/{os.getenv('GRAPH_VERSION', 'v23.0')}"

SUPABASE_URL = os.getenv("SUPABASE_URL", "").rstrip("/")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_KEY", "")
BUCKET = os.getenv("SUPABASE_BUCKET", "cards")

HASHTAGS = os.getenv("IG_HASHTAGS", "#أخبار #عاجل #news")
MAX_PER_DAY = int(os.getenv("IG_MAX_PER_DAY", "8"))
MIN_GAP = int(os.getenv("IG_MIN_GAP_MINUTES", "60")) * 60

enabled = bool(IG_USER_ID and IG_TOKEN and SUPABASE_URL and SUPABASE_KEY)
_posted = []  # أوقات آخر المنشورات


def _sb_headers(**extra):
    headers = {"apikey": SUPABASE_KEY, **extra}
    # المفاتيح الجديدة (sb_secret_...) مو JWT، فتنرسل في apikey بس
    if not SUPABASE_KEY.startswith("sb_"):
        headers["Authorization"] = f"Bearer {SUPABASE_KEY}"
    return headers


def ensure_bucket():
    r = requests.post(f"{SUPABASE_URL}/storage/v1/bucket", timeout=30, headers=_sb_headers(),
                      json={"id": BUCKET, "name": BUCKET, "public": True})
    if r.status_code not in (200, 201) and "already exists" not in r.text.lower():
        r.raise_for_status()


def _upload(png_path):
    # إنستقرام يقبل JPEG بس
    jpg_path = png_path.rsplit(".", 1)[0] + ".jpg"
    Image.open(png_path).convert("RGB").save(jpg_path, "JPEG", quality=92)
    name = os.path.basename(jpg_path)
    with open(jpg_path, "rb") as f:
        r = requests.post(f"{SUPABASE_URL}/storage/v1/object/{BUCKET}/{name}", timeout=60,
                          headers=_sb_headers(**{"Content-Type": "image/jpeg", "x-upsert": "true"}),
                          data=f)
    r.raise_for_status()
    return f"{SUPABASE_URL}/storage/v1/object/public/{BUCKET}/{name}"


def _graph(path, **params):
    r = requests.post(f"{GRAPH}/{path}", timeout=60, data={**params, "access_token": IG_TOKEN})
    if not r.ok:
        raise RuntimeError(f"Instagram {r.status_code}: {r.text[:300]}")
    return r.json()


def _wait_ready(creation_id):
    for _ in range(10):
        r = requests.get(f"{GRAPH}/{creation_id}", timeout=30,
                         params={"fields": "status_code", "access_token": IG_TOKEN})
        status = r.json().get("status_code")
        if status == "FINISHED":
            return
        if status == "ERROR":
            raise RuntimeError(f"Instagram رفض الصورة: {r.text[:300]}")
        time.sleep(3)


def can_post():
    """يمنع النشر الزايد: إنستقرام يعاقب الحسابات اللي تنشر بكثرة."""
    now = time.time()
    _posted[:] = [t for t in _posted if now - t < 86400]
    return enabled and len(_posted) < MAX_PER_DAY and (not _posted or now - _posted[-1] >= MIN_GAP)


def post(png_path, source, title, brand=""):
    caption = f"{title}\n\nالمصدر: {source}"
    if brand:
        caption += f"\nتابع {brand} لآخر الأخبار (الرابط في البايو)"
    caption += f"\n\n{HASHTAGS}"
    url = _upload(png_path)
    creation_id = _graph(f"{IG_USER_ID}/media", image_url=url, caption=caption)["id"]
    _wait_ready(creation_id)
    _graph(f"{IG_USER_ID}/media_publish", creation_id=creation_id)
    _posted.append(time.time())

"""نشر البطاقات كستوري على إنستقرام (Instagram API with Instagram Login).

إنستقرام ما يقبل رفع الصورة مباشرة، لازم تكون على رابط عام.
فنرفعها أول على Supabase Storage (bucket عام) وبعدين نعطي رابطها لإنستقرام.

التوكن يخلص بعد ٦٠ يوم، فنجدده كل أسبوع ونحفظ الجديد في Supabase.
"""
import hashlib, os, time
from datetime import datetime, timedelta, timezone
import requests
from card import make_story
import store

ENV_TOKEN = os.getenv("IG_ACCESS_TOKEN", "")
VERSION = os.getenv("GRAPH_VERSION", "v23.0")
# توكنات Instagram Login تبدأ بـ IG، والباقي توكنات فيسبوك
HOST = "https://graph.instagram.com" if ENV_TOKEN.startswith("IG") else "https://graph.facebook.com"
GRAPH = f"{HOST}/{VERSION}"
BUCKET = os.getenv("SUPABASE_BUCKET", "cards")

MAX_PER_DAY = int(os.getenv("IG_MAX_PER_DAY") or "8")
MIN_GAP = int(os.getenv("IG_MIN_GAP_MINUTES") or "60") * 60

enabled = bool(ENV_TOKEN and store.enabled)
_token = ENV_TOKEN
_user_id = os.getenv("IG_USER_ID", "")


def setup():
    """يجهز الـ bucket، ويختار أحدث توكن ويجدده إذا لزم، ويعرف رقم الحساب."""
    global _token, _user_id
    r = requests.post(f"{store.SUPABASE_URL}/storage/v1/bucket", timeout=30, headers=store.headers(),
                      json={"id": BUCKET, "name": BUCKET, "public": True})
    if r.status_code not in (200, 201) and "already exists" not in r.text.lower():
        r.raise_for_status()

    source_hash = hashlib.sha256(ENV_TOKEN.encode()).hexdigest()
    saved = store.get_ig_token()
    if saved and saved["source_hash"] == source_hash:
        _token = saved["token"]
    else:
        store.save_ig_token(source_hash, ENV_TOKEN)  # توكن جديد في GitHub
        saved = {"refreshed_at": datetime.now(timezone.utc)}

    if HOST.endswith("instagram.com") and datetime.now(timezone.utc) - saved["refreshed_at"] > timedelta(days=7):
        r = requests.get(f"{HOST}/refresh_access_token", timeout=30,
                         params={"grant_type": "ig_refresh_token", "access_token": _token})
        if r.ok:
            _token = r.json()["access_token"]
            store.save_ig_token(source_hash, _token)
            print("تجدد توكن إنستقرام")
        else:
            print(f"ما قدرنا نجدد توكن إنستقرام: {r.text[:200]}")

    if not _user_id:
        r = requests.get(f"{GRAPH}/me", timeout=30, params={"fields": "user_id,username", "access_token": _token})
        if not r.ok:
            raise RuntimeError(f"توكن إنستقرام مرفوض: {r.text[:300]}")
        me = r.json()
        _user_id = str(me.get("user_id") or me["id"])
        print(f"إنستقرام مربوط: @{me.get('username')}")


def _upload(jpg_path):
    name = os.path.basename(jpg_path)
    with open(jpg_path, "rb") as f:
        r = requests.post(f"{store.SUPABASE_URL}/storage/v1/object/{BUCKET}/{name}", timeout=60,
                          headers=store.headers(**{"Content-Type": "image/jpeg", "x-upsert": "true"}),
                          data=f)
    r.raise_for_status()
    return f"{store.SUPABASE_URL}/storage/v1/object/public/{BUCKET}/{name}"


def _graph(path, **params):
    r = requests.post(f"{GRAPH}/{path}", timeout=60, data={**params, "access_token": _token})
    if not r.ok:
        raise RuntimeError(f"Instagram {r.status_code}: {r.text[:300]}")
    return r.json()


def _wait_ready(creation_id):
    for _ in range(10):
        r = requests.get(f"{GRAPH}/{creation_id}", timeout=30,
                         params={"fields": "status_code", "access_token": _token})
        status = r.json().get("status_code")
        if status == "FINISHED":
            return
        if status == "ERROR":
            raise RuntimeError(f"Instagram رفض الصورة: {r.text[:300]}")
        time.sleep(3)


def can_post():
    """يمنع النشر الزايد: إنستقرام يعاقب الحسابات اللي تنشر بكثرة."""
    if not enabled or not _user_id:
        return False
    recent = store.ig_posts_last_day()
    if len(recent) >= MAX_PER_DAY:
        return False
    return not recent or (datetime.now(timezone.utc) - recent[0]).total_seconds() >= MIN_GAP


def post_story(card_path, cta="", accent="#ef4444"):
    story = make_story(card_path, card_path.rsplit(".", 1)[0] + "-story.jpg", cta=cta, accent=accent)
    url = _upload(story)
    creation_id = _graph(f"{_user_id}/media", image_url=url, media_type="STORIES")["id"]
    _wait_ready(creation_id)
    _graph(f"{_user_id}/media_publish", creation_id=creation_id)
    store.record_ig_post()

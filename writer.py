"""يعيد صياغة الأخبار بالعربي عن طريق Claude: يختار المفيد، يترجم العنوان، ويضيف سطر "وش يفيدك".

إذا ANTHROPIC_API_KEY مو موجود، البوت يشتغل عادي بدون ترجمة.
"""
import json, os
import anthropic

MODEL = os.getenv("CLAUDE_MODEL") or "claude-opus-5-5"
enabled = bool(os.getenv("ANTHROPIC_API_KEY"))

SYSTEM = """أنت محرر محتوى لقناة تلقرام وحساب إنستقرام اسمه Hamoud AI Studio (كويتي).
الجمهور: مصممين وصنّاع محتوى ومسوّقين وأصحاب مشاريع في الخليج، يستخدمون الذكاء الاصطناعي لصناعة صور وفيديو وإعلانات منتجات.

بيوصلك مجموعة أخبار. لكل خبر قرر:
- keep: true إذا الخبر يهم هالجمهور (أدوات AI جديدة، تحديثات أدوات الصور والفيديو والكتابة، شي يفيد التصميم والتسويق والإعلانات، أو ترند خفيف ومثير يحب الناس يتابعونه).
- keep: false للأخبار التقنية العميقة اللي ما تهم المصمم، والسياسة، والحروب، والوفيات، والجرائم، وأي شي حساس.

إذا keep: true:
- title: عنوان عربي فصيح وبسيط وجذاب، بحدود ٧٠ حرف. أسماء الأدوات والشركات تبقى بالإنجليزي (مثل Midjourney وOpenAI).
- why: سطر واحد بحدود ١٢٠ حرف يقول وش يفيد المصمم أو صانع المحتوى عملياً. للترندات: سطر يوضح ليش الموضوع ترند.
ما تخترع معلومات مو موجودة في الخبر.
إذا keep: false خلّ title وwhy فاضيين."""

SCHEMA = {
    "type": "object",
    "properties": {
        "items": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "id": {"type": "integer"},
                    "keep": {"type": "boolean"},
                    "title": {"type": "string"},
                    "why": {"type": "string"},
                },
                "required": ["id", "keep", "title", "why"],
                "additionalProperties": False,
            },
        }
    },
    "required": ["items"],
    "additionalProperties": False,
}

_client = anthropic.Anthropic() if enabled else None


def rewrite(items):
    """يرجع (المختارة مع عنوان عربي وسطر why، والمرفوضة). لو صار خطأ يرجع الكل بدون تعديل."""
    if not enabled or not items:
        return items, []
    listing = "\n\n".join(
        f"[{i}] المصدر: {it['feed']['name']}\nالعنوان: {it['title']}\nمقتطف: {it['summary']}"
        for i, it in enumerate(items)
    )
    try:
        response = _client.beta.messages.create(
            model=MODEL,
            max_tokens=16000,
            betas=["server-side-fallback-2026-07-01"],
            fallbacks="default",
            output_config={"effort": "low", "format": {"type": "json_schema", "schema": SCHEMA}},
            system=SYSTEM,
            messages=[{"role": "user", "content": listing}],
        )
    except anthropic.APIError as err:
        print(f"Claude ما رد ({err})، بننشر بدون ترجمة")
        return items, []
    if response.stop_reason == "refusal":
        print("Claude رفض الطلب، بننشر بدون ترجمة")
        return items, []
    text = next(b.text for b in response.content if b.type == "text")
    decisions = {d["id"]: d for d in json.loads(text)["items"]}

    kept, rejected = [], []
    for i, it in enumerate(items):
        d = decisions.get(i)
        if d and d["keep"] and d["title"].strip():
            kept.append({**it, "title": d["title"].strip(), "why": d["why"].strip()})
        elif d:
            rejected.append(it)
        else:
            kept.append(it)  # ما رجع له قرار، نخليه زي ما هو
    return kept, rejected

# ==============================================================================
# انسخ هذا الكود بالكامل وضعه في خلية واحدة (Single Cell) داخل Kaggle Notebook
# تذكر تفعيل GPU (Accelerator -> GPU T4 x2) وتفعيل الإنترنت (Internet -> ON)
# ==============================================================================

import os
import subprocess
import time
import re

print("⏳ 1/4 جاري تثبيت المكتبات (FastAPI, EasyOCR, OpenCV, Google GenAI)...")
os.system("pip install -q fastapi uvicorn python-multipart easyocr opencv-python-headless pillow deep-translator google-genai")

print("⏳ 2/4 جاري تحميل أداة Cloudflare Tunnel لربط السيرفر بتطبيق Flutter...")
if not os.path.exists("cloudflared"):
    os.system("wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -O cloudflared")
    os.system("chmod +x cloudflared")

server_code = r'''
import io
import os
import base64
import json
import cv2
import numpy as np
import easyocr
from PIL import Image
from fastapi import FastAPI, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from deep_translator import GoogleTranslator

app = FastAPI(title="Madomi AI Kaggle Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

print("🚀 Loading EasyOCR Model on GPU...")
reader = easyocr.Reader(['en'], gpu=True)

class GlossaryItem(BaseModel):
    originalName: str
    translatedName: str
    gender: str

class TranslateRequest(BaseModel):
    image_base64: Optional[str] = None
    image_url: Optional[str] = None
    glossary: List[GlossaryItem] = []
    gemini_api_key: Optional[str] = None

def download_or_decode_image(req: TranslateRequest) -> np.ndarray:
    if req.image_base64:
        raw = base64.b64decode(req.image_base64)
        arr = np.frombuffer(raw, dtype=np.uint8)
        return cv2.imdecode(arr, cv2.IMREAD_COLOR)
    elif req.image_url:
        import urllib.request
        req_url = urllib.request.Request(
            req.image_url, 
            headers={'User-Agent': 'Mozilla/5.0'}
        )
        with urllib.request.urlopen(req_url, timeout=15) as resp:
            arr = np.asarray(bytearray(resp.read()), dtype=np.uint8)
            return cv2.imdecode(arr, cv2.IMREAD_COLOR)
    raise ValueError("No image provided")

def group_ocr_lines_into_bubbles(ocr_results, img_w, img_h):
    """يدمج الأسطر المتقاربة داخل نفس فقاعة الكلام في مربع حوار واحد"""
    boxes = []
    for (bbox, text, prob) in ocr_results:
        if prob < 0.25 or len(text.strip()) < 2:
            continue
        xs = [pt[0] for pt in bbox]
        ys = [pt[1] for pt in bbox]
        x1, y1, x2, y2 = int(min(xs)), int(min(ys)), int(max(xs)), int(max(ys))
        boxes.append({'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2, 'text': text.strip()})

    boxes.sort(key=lambda b: (b['y1'], b['x1']))
    merged = []
    for b in boxes:
        if not merged:
            merged.append(b)
            continue
        prev = merged[-1]
        vertical_gap = b['y1'] - prev['y2']
        horiz_overlap = min(prev['x2'], b['x2']) - max(prev['x1'], b['x1'])
        if vertical_gap < (img_h * 0.035) and horiz_overlap > -20:
            prev['x1'] = min(prev['x1'], b['x1'])
            prev['y1'] = min(prev['y1'], b['y1'])
            prev['x2'] = max(prev['x2'], b['x2'])
            prev['y2'] = max(prev['y2'], b['y2'])
            prev['text'] += " " + b['text']
        else:
            merged.append(b)
    return merged

def translate_with_glossary(texts: List[str], glossary: List[GlossaryItem], api_key: Optional[str]) -> List[str]:
    if not texts:
        return []
    
    # 1. إذا وُجد مفتاح Gemini API نستخدم الترجمة السياقية الذكية بالقاموس
    if api_key and len(api_key.strip()) > 10:
        try:
            from google import genai
            client = genai.Client(api_key=api_key.strip())
            glossary_str = "\n".join([f"- {g.originalName} -> {g.translatedName} (Gender: {g.gender})" for g in glossary])
            prompt = f"""أنت مترجم مانهوا محترف إلى اللغة العربية.
التزم تماماً بقاموس الشخصيات والجنس التالي عند صياغة الضمائر والأسماء:
{glossary_str}

ترجم قائمة الجمل التالية بنفس الترتيب وأرجع النتيجة بصيغة JSON Array من النصوص العربية فقط بدون أي شرح:
{json.dumps(texts, ensure_ascii=False)}
"""
            resp = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=prompt,
            )
            raw_json = resp.text.strip().removeprefix("```json").removesuffix("```").strip()
            parsed = json.loads(raw_json)
            if isinstance(parsed, list) and len(parsed) == len(texts):
                return [str(x) for x in parsed]
        except Exception as e:
            print("Gemini fallback to GoogleTranslator:", e)

    # 2. البديل التلقائي المجاني مع استبدال مصطلحات القاموس مباشرة
    translator = GoogleTranslator(source='auto', target='ar')
    translated_list = []
    for t in texts:
        modified_t = t
        for g in glossary:
            if g.originalName.lower() in modified_t.lower():
                modified_t = re.sub(re.escape(g.originalName), g.translatedName, modified_t, flags=re.IGNORECASE)
        try:
            ar = translator.translate(modified_t)
        except Exception:
            ar = modified_t
        translated_list.append(ar)
    return translated_list

@app.get("/health")
def health():
    return {"status": "ok", "engine": "Madomi Kaggle GPU Server"}

@app.post("/translate_page")
def translate_page(req: TranslateRequest):
    img = download_or_decode_image(req)
    h, w, _ = img.shape

    # 1. استخراج أماكن النص الحقيقية عبر EasyOCR
    ocr_raw = reader.readtext(img)
    merged_bubbles = group_ocr_lines_into_bubbles(ocr_raw, w, h)

    # 2. إنشاء قناع المسح (Inpainting Mask) لمسح النص الإنجليزي/الكوري من الصورة الأصلية
    mask = np.zeros((h, w), dtype=np.uint8)
    for b in merged_bubbles:
        pad = 4
        x1 = max(0, b['x1'] - pad)
        y1 = max(0, b['y1'] - pad)
        x2 = min(w, b['x2'] + pad)
        y2 = min(h, b['y2'] + pad)
        cv2.rectangle(mask, (x1, y1), (x2, y2), 255, -1)

    cleaned_img = cv2.inpaint(img, mask, inpaintRadius=5, flags=cv2.INPAINT_TELEA)

    # 3. ترجمة النصوص المستخرجة مع تطبيق قاموس AniList
    original_texts = [b['text'] for b in merged_bubbles]
    arabic_texts = translate_with_glossary(original_texts, req.glossary, req.gemini_api_key)

    # 4. تحويل الصورة الممسوحة النظيفة إلى Base64 لإرسالها لتطبيق Flutter
    _, buffer = cv2.imencode('.jpg', cleaned_img, [int(cv2.IMWRITE_JPEG_QUALITY), 88])
    cleaned_b64 = base64.b64encode(buffer).decode('utf-8')

    bubbles_response = []
    for b, ar_text in zip(merged_bubbles, arabic_texts):
        bubbles_response.append({
            "x": round(b['x1'] / w, 4),
            "y": round(b['y1'] / h, 4),
            "w": round((b['x2'] - b['x1']) / w, 4),
            "h": round((b['y2'] - b['y1']) / h, 4),
            "originalText": b['text'],
            "translatedText": ar_text
        })

    return {
        "status": "success",
        "cleaned_image_base64": cleaned_b64,
        "bubblesCount": len(bubbles_response),
        "bubbles": bubbles_response
    }
'''

with open("server.py", "w", encoding="utf-8") as f:
    f.write(server_code)

print("⏳ 3/4 جاري تشغيل سيرفر FastAPI في الخلفية...")
uvicorn_proc = subprocess.Popen(["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8000"])
time.sleep(5)

print("⏳ 4/4 جاري فتح رابط Cloudflare العام...")
tunnel_proc = subprocess.Popen(
    ["./cloudflared", "tunnel", "--url", "http://localhost:8000"],
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
    text=True
)

public_url = None
for line in tunnel_proc.stdout:
    match = re.search(r"https://[a-zA-Z0-9-]+\.trycloudflare\.com", line)
    if match:
        public_url = match.group(0)
        print("\n" + "="*65)
        print(f"✅ السيرفر يعمل الآن! انسخ هذا الرابط وضعه في تطبيق Flutter:")
        print(f"🔗 {public_url}")
        print("="*65 + "\n")
        break

try:
    uvicorn_proc.wait()
except KeyboardInterrupt:
    uvicorn_proc.terminate()
    tunnel_proc.terminate()

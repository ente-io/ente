import json
import requests
import time

print("=== Starting Persian Translation ===")

arb_files = [
    ("packages/strings/lib/l10n/arb/strings_en.arb", "packages/strings/lib/l10n/arb/strings_fa.arb"),
    ("apps/auth/lib/l10n/arb/app_en.arb", "apps/auth/lib/l10n/arb/app_fa.arb"),
    ("apps/photos/lib/l10n/intl_en.arb", "apps/photos/lib/l10n/intl_fa.arb")
]

API_KEY = os.getenv('OPENAI_API_KEY')
if not API_KEY:
    raise ValueError("❌ OPENAI_API_KEY environment variable not set!")
API_URL = "https://api.gapgpt.app/v1/chat/completions"

all_translations = {}
total_missing = 0
total_translated = 0

for en_file, fa_file in arb_files:
    section = en_file.split("/")[-3]
    print(f"\n=== Processing: {section} ===")
    
    with open(en_file, "r", encoding="utf-8") as f:
        en_data = json.load(f)
    
    with open(fa_file, "r", encoding="utf-8") as f:
        fa_data = json.load(f)
    
    missing = {}
    for key in en_data.keys():
        if key.startswith("@"):
            continue
        if key not in fa_data or not fa_data[key]:
            missing[key] = en_data[key]
    
    print(f"Missing keys: {len(missing)}")
    total_missing += len(missing)
    
    if not missing:
        print("Nothing to translate!")
        continue
    
    translations = {}
    keys = list(missing.keys())
    batch_size = 10
    total_batches = (len(keys) + batch_size - 1) // batch_size
    
    for i in range(0, len(keys), batch_size):
        batch_keys = keys[i:i+batch_size]
        batch_dict = {k: missing[k] for k in batch_keys}
        batch_num = i // batch_size + 1
        
        prompt = "Translate to natural Persian. Return ONLY valid JSON:\n\n"
        prompt += json.dumps(batch_dict, indent=2, ensure_ascii=False)
        
        print(f"Batch {batch_num}/{total_batches}... ", end="", flush=True)
        
        try:
            response = requests.post(
                API_URL,
                headers={
                    "Authorization": f"Bearer {API_KEY}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "gpt-4o-mini",
                    "messages": [
                        {"role": "system", "content": "Persian translator. Return only JSON."},
                        {"role": "user", "content": prompt}
                    ],
                    "temperature": 0.3,
                    "max_tokens": 1000
                },
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                text = result["choices"][0]["message"]["content"]
                
                if "```json" in text:
                    text = text.split("```json")[1].split("```")[0]
                elif "```" in text:
                    text = text.split("```")[1].split("```")[0]
                
                batch_translations = json.loads(text.strip())
                translations.update(batch_translations)
                print(f"OK ({len(batch_translations)} keys)")
                time.sleep(2)
            else:
                print(f"FAILED (HTTP {response.status_code})")
        
        except Exception as e:
            print(f"ERROR: {str(e)[:50]}")
            time.sleep(5)
    
    all_translations[fa_file] = translations
    total_translated += len(translations)
    print(f"Section total: {len(translations)}/{len(missing)}")

with open("translations_output.json", "w", encoding="utf-8") as f:
    json.dump(all_translations, f, ensure_ascii=False, indent=2)

print(f"\n=== COMPLETE ===")
print(f"Total missing: {total_missing}")
print(f"Total translated: {total_translated}")
print(f"Success rate: {total_translated}/{total_missing}")
print(f"\nOutput saved: translations_output.json")

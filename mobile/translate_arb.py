import json
import requests
import time

print("Starting translation...")

arb_files = [
    ("packages/strings/lib/l10n/arb/strings_en.arb", "packages/strings/lib/l10n/arb/strings_fa.arb"),
    ("apps/auth/lib/l10n/arb/app_en.arb", "apps/auth/lib/l10n/arb/app_fa.arb"),
    ("apps/photos/lib/l10n/intl_en.arb", "apps/photos/lib/l10n/intl_fa.arb")
]

api_key = os.getenv('OPENAI_API_KEY')
if not api_key:
    raise ValueError("❌ OPENAI_API_KEY environment variable not set!")
api_url = "https://api.gapgpt.app/v1/chat/completions"
all_results = {}

for en_file, fa_file in arb_files:
    section = en_file.split("/")[-3]
    print(f"Processing: {section}")
    
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
    
    if not missing:
        continue
    
    translations = {}
    keys = list(missing.keys())
    batch_size = 10
    
    for i in range(0, len(keys), batch_size):
        batch_keys = keys[i:i+batch_size]
        batch = {k: missing[k] for k in batch_keys}
        
        prompt = json.dumps(batch, ensure_ascii=False) + "\nTranslate to Persian. Return ONLY JSON."
        
        headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
        payload = {"model": "gpt-4o-mini", "messages": [{"role": "user", "content": prompt}], "temperature": 0.3}
        
        try:
            response = requests.post(api_url, headers=headers, json=payload, timeout=30)
            result = response.json()
            content = result["choices"][0]["message"]["content"].strip()
            
            lines = content.split("\n")
            if len(lines) > 2 and lines[0].strip().startswith("
```"):
content = "\n".join(lines[1:-1])

batch_trans = json.loads(content)
translations.update(batch_trans)
print(f"Batch {i//batch_size + 1}: Done")
time.sleep(2)

except Exception as e:
print(f"Error: {str(e)}")
time.sleep(5)

all_results[fa_file] = translations
print(f"Total: {len(translations)}")

with open("translations_output.json", "w", encoding="utf-8") as f:
json.dump(all_results, f, ensure_ascii=False, indent=2)

total = sum(len(v) for v in all_results.values())
print(f"Done! Total: {total} translations")

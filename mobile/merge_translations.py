import json

print("=== Merging translations into ARB files ===")

with open("translations_output.json", "r", encoding="utf-8") as f:
    all_translations = json.load(f)

for fa_file, translations in all_translations.items():
    print(f"\n📝 Updating: {fa_file}")
    
    with open(fa_file, "r", encoding="utf-8") as f:
        fa_data = json.load(f)
    
    before_count = len(fa_data)
    fa_data.update(translations)
    after_count = len(fa_data)
    
    with open(fa_file, "w", encoding="utf-8") as f:
        json.dump(fa_data, f, ensure_ascii=False, indent=2)
    
    print(f"   Keys before: {before_count}")
    print(f"   Keys after: {after_count}")
    print(f"   Added: {after_count - before_count}")

print("\n✅ All ARB files updated!")

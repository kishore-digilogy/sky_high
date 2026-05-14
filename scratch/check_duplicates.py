import re

def find_duplicate_keys(file_path):
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Language blocks start with 'Name': { and end with },
    # This regex is safer
    language_blocks = re.findall(r"'(\w+)': \{(.*?)\n    \},", content, re.DOTALL)
    
    for lang, block in language_blocks:
        # Find all keys like 'key':
        keys = re.findall(r"^\s+'(\w+)':", block, re.MULTILINE)
        seen = set()
        duplicates = []
        for key in keys:
            if key in seen:
                duplicates.append(key)
            seen.add(key)
        
        if duplicates:
            print(f"Duplicates in {lang}: {duplicates}")
        else:
            print(f"No duplicates in {lang}")

find_duplicate_keys('/Users/CTS13919/Desktop/Flutter Projects/sky_high/lib/core/services/localization_service.dart')

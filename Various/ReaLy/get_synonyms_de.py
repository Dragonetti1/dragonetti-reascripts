-- @version 0.1.0

import sys
import requests
import random

def get_synonyms(word):
    url = f"https://www.openthesaurus.de/synonyme/search?q={word}&format=application/json"
    response = requests.get(url)
    
    if response.status_code == 200:
        data = response.json()
        synonyms = set()
        
        # Extract synonyms from the API response
        for synset in data.get("synsets", []):
            for term in synset.get("terms", []):
                synonyms.add(term["term"])
        
        # Convert to list, shuffle, and limit to 8 synonyms
        synonyms = list(synonyms)
        random.shuffle(synonyms)
        return synonyms[:8]  # Return up to 8 synonyms
    else:
        print("Error:", response.status_code)
        return []

# Ensure a word is provided; if not, exit silently
if len(sys.argv) > 1:
    word = sys.argv[1]
    synonyms = get_synonyms(word)
    if synonyms:
        print(",".join(synonyms))  # Print synonyms as a comma-separated string
    else:
        print("No synonyms found.")

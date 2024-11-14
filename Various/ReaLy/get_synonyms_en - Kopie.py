# @noindex

import sys
import requests

def get_synonyms(word):
    try:
        # Anfrage an die Datamuse API, um Synonyme zu erhalten
        response = requests.get(f"https://api.datamuse.com/words?rel_syn={word}")
        # Überprüfen, ob die Anfrage erfolgreich war
        if response.status_code == 200:
            # Extrahiere die Wörter aus der Antwort
            words = [item['word'] for item in response.json()]
            return words[:24]  # Gibt bis zu 24 Begriffe zurück
        else:
            print(f"Error: Received status code {response.status_code}")
            return []
    except Exception as e:
        print(f"Error fetching data from Datamuse API: {e}")
        return []

# Hauptprogramm
if len(sys.argv) > 1:
    word = sys.argv[1]
    synonyms = get_synonyms(word)
    if synonyms:
        print(",".join(synonyms))  # Gibt Synonyme als komma-separierte Zeichenkette aus

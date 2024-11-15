# @noindex

import sys
import requests

def get_synonyms(word):
    # API-URL mit deutschem Thesaurus
    url = f"https://www.openthesaurus.de/synonyme/search?q={word}&format=application/json"
    try:
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        synonyms = set()
        
        # Synonyme aus der API-Antwort extrahieren
        for synset in data.get("synsets", []):
            for term in synset.get("terms", []):
                synonyms.add(term["term"])
        
        # Konvertiere zu Liste und begrenze auf 32 Synonyme
        synonyms = list(synonyms)
        return synonyms[:32]  # Maximal 32 Synonyme zurückgeben
    except requests.exceptions.RequestException as e:
        print(f"Fehler bei der API-Anfrage: {e}", file=sys.stderr)
        return []

if __name__ == "__main__":
    if len(sys.argv) > 1:
        word = sys.argv[1]
        synonyms = get_synonyms(word)
        if synonyms:
            # Ausgabe der Synonyme in UTF-8
            sys.stdout.buffer.write(",".join(synonyms).encode("utf-8"))
        else:
            sys.stdout.buffer.write(b"Keine Synonyme gefunden.")

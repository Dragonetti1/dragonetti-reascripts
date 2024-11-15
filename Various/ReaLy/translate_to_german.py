# @noindex

import sys
from googletrans import Translator

def translate_text(text, dest_lang="de"):
    translator = Translator()
    text = text.replace("NEWLINE_MARKER", "\n")
    translated = translator.translate(text, dest=dest_lang)
    return translated.text

if __name__ == "__main__":
    text = sys.argv[1]
    translated_text = translate_text(text)
    # Stelle sicher, dass die Ausgabe UTF-8 ist
    sys.stdout.buffer.write(translated_text.encode('utf-8'))

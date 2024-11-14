# @noindex

import sys
from googletrans import Translator

def translate_text(text, dest_lang="de"):
    translator = Translator()
    # Replace placeholder with actual newline
    text = text.replace("NEWLINE_MARKER", "\n")
    translated = translator.translate(text, dest=dest_lang)
    return translated.text

if __name__ == "__main__":
    # Read text from arguments, unescape "NEWLINE_MARKER"
    text = sys.argv[1]
    translated_text = translate_text(text)
    print(translated_text)

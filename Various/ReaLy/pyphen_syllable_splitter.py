


import pyphen
import sys

def split_text_into_syllables(text, language):
    dic = pyphen.Pyphen(lang=language)
    lines = text.split("NEWLINE_MARKER")
    syllable_lines = []

    for line in lines:
        syllable_line = " ".join(dic.inserted(word) for word in line.split())
        syllable_lines.append(syllable_line)

    return "NEWLINE_MARKER".join(syllable_lines)

if __name__ == "__main__":
    text = sys.argv[1]
    language = sys.argv[2]
    result = split_text_into_syllables(text, language)
    print(result)

import sys
import nltk
import random
from nltk.corpus import wordnet

# Download WordNet if not already downloaded
nltk.download('wordnet', quiet=True)

def get_synonyms(word):
    synonyms = set()
    for syn in wordnet.synsets(word):
        for lemma in syn.lemmas():
            synonyms.add(lemma.name())
    # Convert to list and shuffle to get a random selection
    synonyms = list(synonyms)
    random.shuffle(synonyms)
    return synonyms[:8]  # Return up to 8 synonyms

# Ensure a word is provided; if not, exit silently
if len(sys.argv) > 1:
    word = sys.argv[1]
    synonyms = get_synonyms(word)
    if synonyms:
        print(",".join(synonyms))  # Print synonyms as a comma-separated string

import nltk
import sys
import json
import string

f = open(sys.argv[1], 'r') 
raw  = f.read()
clean = filter(lambda x: x in string.printable, raw)
tokens = nltk.word_tokenize(clean)
porter = nltk.PorterStemmer()
word_set = set(w.lower() for w in tokens if w.isalpha())
print(json.dumps(list(word_set)))

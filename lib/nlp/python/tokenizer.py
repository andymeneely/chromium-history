import nltk
import sys
import json
import string

raw = open(sys.argv[1], 'r')
tokens = []
for line in raw:
  if len(line.strip()) == 0:
    continue
  clean = filter(lambda x: x in string.printable, line)
  for sent in nltk.sent_tokenize(clean):
    tokens += nltk.word_tokenize(sent)

porter = nltk.PorterStemmer()
word_set = set(porter.stem(w) for w in tokens if w.isalpha())
print(json.dumps(list(word_set)))

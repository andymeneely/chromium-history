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

snowball = nltk.SnowballStemmer("english")
stem_lookup = {}
for w in tokens: 
  if w.isalpha():
    stem_lookup[snowball.stem(w)] = w
print(json.dumps(stem_lookup))

import nltk
import sys
import json
from word_bag import WordBag

f = open(sys.argv[2], 'r')
category = sys.argv[1]
word_list = json.loads(f.read())

bag = WordBag()
technical_words = bag.word_difference(word_list, nltk.corpus.words.words())
if category != 'all': 
  technical_words = bag.word_difference(technical_words, nltk.corpus.brown.words(categories=category))
else:
  technical_words = bag.word_difference(technical_words, nltk.corpus.brown.words())
print(json.dumps(list(technical_words)))
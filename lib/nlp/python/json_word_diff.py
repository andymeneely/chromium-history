import nltk
import sys
import json
from word_bag import WordBag

f = open(sys.argv[1], 'r')
word_list = json.loads(f.read())

bag = WordBag()
technical_words = bag.word_difference(word_list, nltk.corpus.words.words())
technical_words = bag.word_difference(technical_words, nltk.corpus.brown.words(categories='news'))
print(json.dumps(list(technical_words)))
import nltk
import sys
import json
from word_bag import WordBag

bag = WordBag()
wordlist = nltk.corpus.PlaintextCorpusReader(sys.argv[1], sys.argv[2])
technical_words = wordlist.words()
technical_words = bag.word_difference(technical_words, nltk.corpus.words.words())
technical_words = bag.word_difference(technical_words, nltk.corpus.brown.words(categories='news'))

print(json.dumps(technical_words))

import nltk
import sys
import json
from word_bag import WordBag

bag = WordBag()
wordlist = nltk.corpus.PlaintextCorpusReader(sys.argv[1], sys.argv[2])
technical_words = wordlist.words()
technical_words = bag.word_difference(technical_words, nltk.corpus.words.words())
technical_words = bag.word_difference(technical_words, nltk.corpus.webtext.words())
technical_words = bag.word_difference(technical_words, nltk.corpus.brown.words())
# technical_words = bag.word_difference(technical_words, nltk.corpus.brown.words(categories='reviews'))
technical_words = bag.word_difference(technical_words, nltk.corpus.gutenberg.words())
# technical_words = bag.word_intersection(technical_words, nltk.corpus.reuters.words())

technical_words = bad.purge(wordlist.words, technical_words)
print(json.dumps(technical_words))

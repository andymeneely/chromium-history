f = open(arg[1], 'r')
word_list = json.loads(f.read)

technical_words = word_difference(word_list, nltk.corpus.words.words())
technical_words = word_difference(technical_words, nltk.corpus.webtext.words())
technical_words = word_difference(technical_words, nltk.corpus.brown.words(categories='news'))
print(json.dumps(technical_words))
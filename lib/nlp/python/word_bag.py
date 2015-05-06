import nltk

class WordBag:

  # Straight from ntlk docs
  def word_difference(self, vocab, corpus_words):
    corpus_vocab = self.build_vocab(corpus_words)
    diff = set(vocab) - corpus_vocab
    return diff

  def word_intersection(self, vocab, corpus_words):
    corpus_vocab = self.build_vocab(corpus_words)
    sect = set(vocab).intersection(corpus_vocab)
    return sect

  def build_vocab(self, source):
    snowball = nltk.SnowballStemmer("english")
    return set(snowball.stem(w) for w in source if w.isalpha())




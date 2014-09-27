
class WordBag:

  # Straight from ntlk docs
  def word_difference(self, text, corpus_words):
    text_vocab = self.build_vocab(text)
    corpus_vocab = self.build_vocab(corpus_words)
    diff = text_vocab - corpus_vocab
    return sorted(diff)

  def word_intersection(self, text, corpus_words):
    text_vocab = self.build_vocab(text)
    corpus_vocab = self.build_vocab(corpus_words)
    sect = text_vocab & corpus_vocab
    return sorted(sect)

  def build_vocab(self, source):
    return set(w.lower() for w in source if w.isalpha())

  def purge(self, words, woot):
    jah = array()
    for word in woot:
      c = words.count(word)
      if(c > 2):
        jah.insert(word)


    return jah



require 'oj'

class VocabLoader

  @@STEM_BLACKLIST = []

  @@CWE_GLOSSARY_TERMS = [
    'actor',
    'attacker',
    'authentication',
    'authorization',
    'behavior',
    'crud',
    'canonicalization',
    'canonicalize',
    'category',
    'chain',
    'check',
    'cleanse',
    'cleansing',
    'cleartext',
    'composite',
    'consequence',
    'enforce',
    'entry',
    'equivalence',
    'filter',
    'filtering',
    'graph',
    'handle',
    'icta',
    'improper',
    'incorrect',
    'insecure',
    'insufficient',
    'internal',
    'leading',
    'manipulation',
    'missing',
    'neutralization',
    'neutralize',
    'node',
    'permissions',
    'pillar',
    'plaintext',
    'policy',
    'property',
    'reliance',
    'resolution',
    'resolve',
    'resource',
    'sdlcsanitization',
    'sanitize',
    'slice',
    'trailing',
    'unexpected',
    'variant',
    'view',
    'vulnerability',
    'weakness'
  ]

  @@OBVIOUS_SECURITY_WORDS = %w(
    security
    confidentiality
    integrity
    availability
    cryptography
    crytpanalysis
  )

  def initialize
    @tmp_dir = Rails.configuration.tmpdir
    @data_dir = Rails.configuration.datadir
  end

  def parse_scrape_results
    acm_scrape = Oj.load_file "#{@data_dir}/acm/acm.json"
    raw = "#{@data_dir}/acm/raw_acm.txt"
    File.open raw, 'w+' do |file|
      acm_scrape['pages'].each do |page|
        file.write page['results']['abstracts'].strip
        file.write "\n"
      end
      file.fsync
    end
    abstracts = []
    categories = Hash.new
    linker = []
    cI = 1
    aI = 1
    acm_scrape['pages'].each do |page|
      page['results']['categories'].each do |category|
        cat = category['category'].strip
        unless categories.has_key? cat
          categories[cat] = cI
          cI += 1
        end
        linker << [aI, categories[cat]]
      end
      abstracts << [aI, page['results']['abstracts']]
      aI += 1
    end
    
    linker.uniq!

    PsqlUtil.create_upload_file "#{@tmp_dir}/acm_categories.csv" do |table|
      categories.each do |category, index|
        table << [index, category]
      end
    end
    PsqlUtil.create_upload_file "#{@tmp_dir}/acm_abstracts.csv" do |table|
      abstracts.each do |abstract|
        table << [abstract[0], abstract[1]]
      end
    end
    PsqlUtil.create_upload_file "#{@tmp_dir}/acm_abstracts_acm_categories.csv" do |table|
      linker.each do |link|
        table << [link[0], link[1]]
      end
    end
  end

  def load
    PsqlUtil.copy_from_file 'acm_categories', "#{@tmp_dir}/acm_categories.csv"
    PsqlUtil.add_primary_key 'acm_categories'
    PsqlUtil.execute "CREATE UNLOGGED TABLE acm_abstracts (id integer, text text)"
    PsqlUtil.copy_from_file 'acm_abstracts', "#{@tmp_dir}/acm_abstracts.csv"
    PsqlUtil.add_index 'acm_abstracts', 'id'
    PsqlUtil.add_fulltext_search_index 'acm_abstracts', 'text'
    PsqlUtil.execute "CREATE UNLOGGED TABLE acm_abstracts_acm_categories (acm_abstract_id integer, acm_category_id integer)"
    PsqlUtil.copy_from_file 'acm_abstracts_acm_categories', "#{@tmp_dir}/acm_abstracts_acm_categories.csv"
    generate_vocab
  end

  def generate_vocab 
    raw = @tmp_dir+'/raw_messages.txt'
    Message.get_all_messages raw
    VocabLoader.clean_file raw, @tmp_dir+'/messages.txt'
    File.unlink raw
    acm_corpus = Corpus.new "#{@data_dir}/acm/raw_acm.txt"
    message_corpus = Corpus.new "#{@tmp_dir}/messages.txt"
    acm_corpus.filter!
    message_corpus.filter!
    words = message_corpus.word_intersect acm_corpus.words
    words = words.each.map {|stem| [stem, true, acm_corpus.stem_lookup[stem]]}

    #Inject curated list after filtering
    words += stem_words(@@CWE_GLOSSARY_TERMS).each_with_index.map {|word, index| [word, false, @@CWE_GLOSSARY_TERMS[index]]}
    words += stem_words(@@OBVIOUS_SECURITY_WORDS).each_with_index.map {|word, index| [word, false, @@OBVIOUS_SECURITY_WORDS[index]]}
    block = lambda do |table|
      words.each do |word|
        table << word
      end
    end
    vocab_file = "#{@tmp_dir}/vocab.csv"
    PsqlUtil.create_upload_file vocab_file, &block
    PsqlUtil.copy_from_file 'technical_words', vocab_file
    PsqlUtil.add_auto_increment_key 'technical_words'
  end

  def reassociate_messages
    reassociate 'messages', 'text', 'messages_technical_words'
    PsqlUtil.add_index 'messages_technical_words', 'message_id', 'hash'
    PsqlUtil.add_index 'messages_technical_words', 'technical_word_id', 'hash'
  end

  def reassociate_categories
    PsqlUtil.execute "CREATE UNLOGGED TABLE acm_abstracts_technical_words (acm_abstract_id integer, technical_word_id integer)"
    reassociate 'acm_abstracts', 'text', 'acm_abstracts_technical_words'
    sql = "INSERT INTO acm_categories_technical_words (
            SELECT 
              aaac.acm_category_id AS acm_category_id,
              t.id AS technical_word_id
            FROM technical_words t
            JOIN acm_abstracts_technical_words aatw
            ON aatw.technical_word_id = t.id
            JOIN acm_abstracts_acm_categories aaac
            ON aaac.acm_abstract_id = aatw.acm_abstract_id
          )"
    PsqlUtil.execute sql
    PsqlUtil.execute "DROP TABLE acm_abstracts; DROP TABLE acm_abstracts_acm_categories; DROP TABLE acm_abstracts_technical_words;"
  end

  def associate_code_review_descriptions
    reassociate 'code_reviews', 'description', 'code_reviews_technical_words', 'issue'
  end

  def associate_git_log_messages
    reassociate 'commits', 'message', 'commits_technical_words'
  end

  def reassociate target_table, searchable_field, linking_table, index_id='id'
    tmp_file = "#{@tmp_dir}/copy_tmp.csv"
    query = " 
      SELECT 
        a.#{index_id}, 
        t.id 
      FROM 
        #{target_table} a, 
        technical_words t 
      WHERE 
        to_tsvector('english', a.#{searchable_field}) @@ to_tsquery(t.word)
     "
    PsqlUtil.copy_to_file query, tmp_file
    PsqlUtil.copy_from_file linking_table, tmp_file
  end

  def stem_words words
    stemmed_words = []
    words.each do |word|
      stemmed_words << PsqlUtil.execute("SELECT ts_lexize('english_stem', '#{word}')")[0]['ts_lexize'].gsub(/\{|\}/, '')
    end
    stemmed_words
  end

  def self.clean_file target_file, output_file
    file = File.open target_file, 'r'
    new_file = VocabLoader.remove_uris file.read
    new_file = VocabLoader.trim_whitespace new_file
    new_file = VocabLoader.remove_nonword new_file
    File.open(output_file, 'w+') { |file| file.write(new_file) }
  end

  def self.clean_messages string
    new_file = VocabLoader.remove_quoted_comments string
    new_file = new_file.gsub(/^On.*wrote:$/, '')
  end

  def self.remove_uris string
    string.gsub(/^(?:#{ URI.scheme_list.keys.join('|') })/i, '')
  end

  def self.trim_whitespace string
    string.gsub(/[\s{2,}]/, ' ')
  end 

  def self.remove_nonword string
    string.gsub(/[^\w\s]/, '')
  end
end

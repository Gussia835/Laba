require 'set'
require_relative 'FraudNormalize'
require_relative 'NameNormalize'

module VoteCleaner
  class Cleaner
    TOP_CANDIDATES = 250
    FRAUD_THRESHOLD = 5
    MAX_DISTANCE = 2

    
    def initialize(file_path)
      @file_path = file_path
      @original_votes = {}
      @correct_votes = Hash.new(0)
      @ip_by_vote = {}
      @suspicious_ips = Set.new
      @suspicious_removed_votes = Hash.new(0)
      @canonical_map = {}
      @grouped_canonicals = Hash.new { |h, k| h[k] = [] }
      @canonical_spellings = Hash.new { |h, k| h[k] = Set.new }
    end

    def analyze
      parse_votes
      detect_fraud_ips
      normalize_names_and_count_votes
      generate_report
    end

    def parse_votes
      File.foreach(@file_path) do |line|
        next if line.empty?
        
        # Исправленное извлечение IP и кандидата
        ip_match = line.match(/ip: ([^,]+)/)
        candidate_match = line.match(/candidate: (.+)$/)
        
        next unless ip_match && candidate_match
        
        ip = ip_match[1].strip
        candidate = candidate_match[1].strip

        @original_votes[candidate] ||= 0
        @original_votes[candidate] += 1
        
        @ip_by_vote[ip] ||= []
        @ip_by_vote[ip] << candidate
      end
    end

    def normalize_names_and_count_votes
      
      top_candidates = @original_votes.sort_by { |_, count| -count }.first(TOP_CANDIDATES).map(&:first)
      
      
      top_candidates.each do |name|
        len = name.length
        @grouped_canonicals[len] << name
      end

      
      @ip_by_vote.each do |ip, votes|
        is_suspicious = @suspicious_ips.include?(ip)
        voted_canonicals = Set.new

        votes.each do |raw_name|
          canonical = find_canonical_name(raw_name)

          if is_suspicious
            if voted_canonicals.include?(canonical)
              @suspicious_removed_votes[canonical] += 1
            else
              @correct_votes[canonical] += 1
              voted_canonicals << canonical
              @canonical_spellings[canonical] << raw_name
            end
          else
            @correct_votes[canonical] += 1
            @canonical_spellings[canonical] << raw_name
          end
        end
      end
    end

    def generate_report
      puts "\n" + "="*80
      puts "СРАВНЕНИЕ: БЫЛО — СТАЛО (после нормализации имён и удаления фрода)"
      puts "="*80

      
      all_candidates = (@original_votes.keys + @correct_votes.keys).uniq

      all_candidates.sort_by { |name| -@correct_votes.fetch(name, 0) }.each do |name|
        raw_count = @original_votes[name] || 0
        final_count = @correct_votes[name] || 0
        removed = @suspicious_removed_votes[name] || 0

        
        absorbed = 0
        @canonical_map.each do |raw, canon|
          absorbed += @original_votes[raw] || 0 if canon == name && raw != name
        end

        puts "#{name}:"
        puts "    Было (сырые голоса): #{raw_count}"
        puts "    Поглощено из опечаток: #{absorbed}"
        puts "    Удалено из-за фрода: #{removed}"
        puts "    Итого: #{final_count}"
        puts "-"*40
      end

      # Топ-20 кандидатов
      puts "\n" + "="*50
      puts "ТОП-20 КАНДИДАТОВ (после обработки)"
      puts "="*50
      top20 = @correct_votes.sort_by { |_, count| -count }.first(20)
      top20.each_with_index do |(name, count), i|
        puts "#{i+1}. #{name} — #{count} голосов"
      end

      # Подозрительные IP
      puts "\n" + "="*50
      puts "ПОДОЗРИТЕЛЬНЫЕ IP (накрутка)"
      puts "="*50
      if @suspicious_ips.empty?
        puts "Не обнаружено"
      else
        @suspicious_ips.each do |ip|
          vote_count = @ip_by_vote[ip].size
          puts "- #{ip} (#{vote_count} голосов)"
        end
      end

      # Недобросовестные участники
      puts "\n" + "="*50
      puts "НЕДОБРОСОВЕСТНЫЕ УЧАСТНИКИ (по количеству вариантов написания)"
      puts "="*50
      fraudulent = @canonical_spellings.sort_by { |_, spellings| -spellings.size }.first(2)
      fraudulent.each_with_index do |(name, spellings), i|
        puts "#{i+1}. #{name} — #{spellings.size} вариантов написания"
      end
    end
  end
end
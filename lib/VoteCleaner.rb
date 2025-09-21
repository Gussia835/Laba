require 'set'
require 'time'
require_relative 'utils/FraudNormalize'
require_relative 'utils/NameNormalize'
require_relative 'utils/FastVoting'
require_relative 'utils/BadnessSpelling'

module VoteCleaner
  class Cleaner
    TOP_CANDIDATES = 250
    FRAUD_THRESHOLD = 5
    MAX_DISTANCE = 2
    TIME_THRESHOLD = 1
    INTERVALS_TIMES = 3
    BADNESS_SPELLING_RATIO = 0.05

    attr_reader :original_votes, :correct_votes, :suspicious_ips_by_votesCount, 
                :suspicious_ips_by_fast, :canonical_spellings, :suspicious_removed_votes

                
    #===========================================
    #             Конструктор
    #===========================================
    def initialize(file_path)
      @file_path = file_path

      @original_votes = {}
      @correct_votes = Hash.new(0)

      @ip_by_vote = {}

      @suspicious_removed_votes = Hash.new(0)
      @suspicious_ips_by_votesCount = Set.new
      @suspicious_ips_by_fast = Set.new
      
      @grouped_canonicals = Hash.new { |h, k| h[k] = [] }
      @canonical_map = {}
      
      @vote_timestamps = Hash.new { |h, k| h[k] = [] }
      @ip_candidate_map = Hash.new { |h, k| h[k] = Set.new }
      @canonical_spellings = Hash.new { |h, k| h[k] = Set.new }
    end

    #=============================================
    #                   Начать 
    #=============================================
    def start
      parse_votes
      detect_fraud_ips
      detect_fast_voting_ips
      normalize_names_and_count_votes
      generate_report
    end

    private

    #============================================
    #     Парсинг голосов, времени и имен
    #============================================
    def parse_votes
      File.foreach(@file_path) do |line|
        next if line.empty?
        
        ip_match = line.match(/ip: ([^,]+)/)
        candidate_match = line.match(/candidate: (.+)$/)
        time_match = line.match(/time: ([^,]+)/)
        
        next unless ip_match && candidate_match && time_match
        
        ip = ip_match[1].strip
        candidate = candidate_match[1].strip
        time_str = time_match[1].strip
        
        time = Time.parse(time_str) rescue nil
        next unless time
        
        @original_votes[candidate] ||= 0
        @original_votes[candidate] += 1
        
        @ip_by_vote[ip] ||= []
        @ip_by_vote[ip] << candidate
        
        @vote_timestamps[ip] << time
        @ip_candidate_map[ip] << candidate

      end
    end


    #===========================================================================
    #     Получение корректных имен кандидатов и количества голосов за них
    #===========================================================================

    def normalize_names_and_count_votes
      top_candidates = @original_votes.sort_by { |_, count| -count }.first(TOP_CANDIDATES).map(&:first)
      
      top_candidates.each do |name|
        len = name.length
        @grouped_canonicals[len] << name
      end

      @ip_by_vote.each do |ip, votes|
        is_suspicious = @suspicious_ips_by_votesCount.include?(ip) || @suspicious_ips_by_fast.include?(ip)
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


    #=============================================================
    #         Получение ip которые голосовали за кандидата
    #==============================================================
    def get_ips_for_candidate(candidate_name)
      ips = Set.new
      
      @ip_by_vote.each do |ip, votes|
        votes.each do |raw_name|
          canonical = find_canonical_name(raw_name)
          ips << ip if canonical == candidate_name
        end
      end
      
      ips
    end


    #========================================
    #         Вывод информации
    #=======================================
    def generate_report
      puts "\n" + "="*70
      puts "ТОП-20 КАНДИДАТОВ (после обработки)"
      puts "="*70
      top20 = @correct_votes.sort_by { |_, count| -count }.first(20)
      top20.each_with_index do |(name, count), i|
        puts "#{i+1}. #{name} — #{count} голосов"
      end

      puts "\n" + "="*70
      puts "ПОДОЗРИТЕЛЬНЫЕ IP (по количеству голосов)"
      puts "="*70

      if @suspicious_ips_by_votesCount.empty?
        puts "Не обнаружено"

      else
        @suspicious_ips_by_votesCount.each do |ip|
          vote_count = @ip_by_vote[ip].size
          puts "- #{ip} (#{vote_count} голосов) - #{@ip_by_vote[ip][0]}"
        end
      end
      
      puts "\n" + "="*70
      puts "ПОДОЗРИТЕЛЬНЫЕ IP (быстрое голосование)"
      puts "="*70
      
      fast_voting_ips = @suspicious_ips_by_fast
      if fast_voting_ips.empty?
        puts "Не обнаружено"

      else
        fast_voting_ips.each do |ip|
          times = @vote_timestamps[ip].sort
          vote_count = times.size
    
          intervals = []
          times.each_cons(2) do |t1, t2|
            intervals << (t2 - t1)
          end
    
          min_interval = intervals.min
          avg_interval = intervals.sum / intervals.size
          max_interval = intervals.max
          
          puts "#{@ip_by_vote[ip][0]}"
          puts "- #{ip} (#{vote_count} голосов):"
          puts "  Средний интервал: #{avg_interval.round(2)} сек"
          puts "  Минимальный интервал: #{min_interval.round(2)} сек"
          puts "  Максимальный интервал: #{max_interval.round(2)} сек"
          puts "" 

        end

      end

      puts "\n" + "="*70
      puts "НЕДОБРОСОВЕСТНЫЕ УЧАСТНИКИ (по количеству вариантов написания)"
      puts "="*70
      fraudulent = @canonical_spellings.sort_by { |_, spellings| -spellings.size }.first(1)
      fraudulent.each_with_index do |(name, spellings), i|
        #ips = get_ips_for_candidate(name)
        puts "#{i+1}. #{name} — #{spellings.size} вариантов написания"
        #puts "   IP-адреса: #{ips.to_a.join(', ')}"

      end

      puts "\n" + "="*70
      puts "ПОДОЗРИТЕЛЬНЫЕ УЧАСТНИКИ (слишком правильное написание)"
      puts "="*70
      badness_candidates = detect_badness_spelling_candidates
      if badness_candidates.empty?
        puts "Не обнаружено"

      else
        badness_candidates.sort_by { |_, data| -data[:ratio] }.each_with_index do |(name, data), i|
          #ips = get_ips_for_candidate(name)
          puts "#{i+1}. #{name} — #{'%.2f' % (data[:ratio] * 100)}% правильных написаний"
          puts "   Всего голосов: #{data[:total_votes]}, Правильных: #{data[:perfect_votes]}"
          #puts "   IP-адреса: #{ips.to_a.join(', ')}"
        end
      end

    end
  end
end
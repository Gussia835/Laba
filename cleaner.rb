require "fast_levenstein"

module VoteCleaner
  class Cleaner

    # ==================================================
    #               Инициализация
    # ==================================================
    def initialize(candidates)
      @votes = extract_candidates(candidates)
      
      @classified_names = Hash.new() { |h,k| h[k] = [] }
      @clusters = {} 
      
      @top_candidates = {}

    end


    private


    # ==================================================
    #     Извечение из файла имен всех кандидатов
    # ==================================================
    def extract_candidates(raws)
      raws.map do |r|
        if r.include?("candidate: ")
          r.split("candidate: ").last.strip
        
        else
          ""
        end

      end.reject(&:empty?)
    end

    # ==================================================
    #   Кластеризация имен с опечатками и правильных 
    # ==================================================
    def cluster_names()
      @votes.each do |name|
        next if @classified_names.key?(name)
          
        found_canonic = false
        @classified_names.keys.each do |key_name|
          dist = Levenstein.distance(name, key_name)
            
          if (dist <= 2) 
            found_canonic = true
            @classified_names[key_name] << name
            break  
          end    
        end

        unless (found_canonic)
          @classified_names[name] = name
          @clusters[name] = [name]
        end
      
        print "\rПрогресс: #{idx + 1}/#{@votes.size}" if idx % 10000 == 0
      end
      puts
    end

    # ==================================================
    #   Кластеризация голосов с учетом опечаток в именах 
    # ==================================================
    def count_votes()
    
    end




    end
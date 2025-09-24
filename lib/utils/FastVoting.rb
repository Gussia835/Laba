module VoteCleaner
  class Cleaner
    private

    #===========================================
    #       Проверка по скорости ответов
    #===========================================
    def detect_fast_voting_ips
      @vote_timestamps.each do |name, times|
        fast_intervals = 0
        times.sort!

        times.each_cons(2) do |t1, t2|
          if (t2 - t1) <= TIME_THRESHOLD
            fast_intervals += 2
          end

          if fast_intervals >= INTERVALS_TIMES
            @suspicious_ips_by_fast << name
            break
          end
        end
      end
          
      puts "Найдено подозрительных IP (по скорости голосования): #{@suspicious_ips_by_fast.size}" unless @suspicious_ips_by_fast.empty?
    end
  end
end
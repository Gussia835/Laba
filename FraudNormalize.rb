module VoteCleaner
  class Cleaner

    #=========================================================
    #               Определяет фальшивые ip
    #=========================================================
    def detect_fraud_ips
      @ip_by_vote.each do |ip, votes|
        @suspicious_ips << ip if votes.size > FRAUD_THRESHOLD
      end
      puts "Найдено подозрительных IP: #{@suspicious_ips.size}"
    end
  end
end
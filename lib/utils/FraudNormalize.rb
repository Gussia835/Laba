module VoteCleaner
  class Cleaner
    private

    #=====================================================
    #   Получает подозрительные ip по количеству голосов
    #=====================================================
    def detect_fraud_ips
      @ip_by_vote.each do |ip, votes|
        @suspicious_ips_by_votesCount << ip if votes.size > FRAUD_THRESHOLD
      end
      puts "Найдено подозрительных IP (по количеству голосов): #{@suspicious_ips_by_votesCount.size}"
    end
  end
end
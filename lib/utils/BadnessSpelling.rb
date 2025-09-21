module VoteCleaner
  class Cleaner
    private

    #======================================
    #       Плохое написание
    #======================================
    def detect_badness_spelling_candidates
      badness_candidates = {}
      
      @canonical_spellings.each do |candidate, spellings|
        total_votes = @correct_votes[candidate] + @suspicious_removed_votes[candidate]
        perfect_votes = spellings.count { |spelling| spelling == candidate }
        perfect_ratio = perfect_votes.to_f / total_votes
        
        if perfect_ratio >= BADNESS_SPELLING_RATIO && total_votes > 10
          badness_candidates[candidate] = {
            ratio: perfect_ratio,
            total_votes: total_votes,
            perfect_votes: perfect_votes
          }
        end
      end
      
      badness_candidates
    end
  end
end
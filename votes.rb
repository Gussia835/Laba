require 'set'

path_votes = 'votes.txt'


def levenstein(s, t, max)
    return 0 if s==t
    
    n = s.size
    m = t.size

    return max+1 if (n-m).abs > max

    row = (0..1).to_a
    min_val = n

    (1..n).each do |i|
        prev = row[0]
        row[0] = i
        min_val = i

        (1..m).each do |j|
            old = row[j]
            cost_replace = (s[i-1]==t[j-1]) ? 0 : 1
            row[j] = [row[j-1]+1, row[j]+1, prev+cost_replace].min
            min_val = [min_val, row[j]].min
            prev = old
        end

        return max+1 if min_val > max
    end

    row[m] <= max ? row[m] : max+1
end


class analyzer_votes

    def initialize(path_vote)
        
        @name_candidates_list = []
        @candidate_vote_dict = Hash.new() 
        File.readlines(path_vote).each do |line|
                if line.include?(', candidate: ')
                    name = line.split(', candidate: ').last.chomp
                    @name_candidates_list << name
                    @candidate_vote_dict[name] += 1
            else
                puts "invalid file_read: #{line}";
            end
        end

        cluster_variants

        @grouped_canoncials = Hash.new { |h,k| h[k] = [] }
        @canoncial_names.each do |name|
            len = name.length
            @grouped_canoncials[len] << name
        end

        @candidate_votes = Hash.new(0)
        @candidate_spellings = Hash.new { |h, k| h[k] = Set.new }

    end
        

    def cluster_variants
        @top_candidates = @candidate_vote_dict.keys.sort_by { |k| -@candidate_vote_dict[k] }[0,250]

        @canonical_names = []
        @variant_to_canonic = {}

        @grouped_by_len = Hash.new() { |h, k| h[k] = [] }
        @top_candidates.each { |v| @grouped_by_len[v.length] << v }


        @top_candidates.keys.each { |v| -@top_candidates[v] }.each do |variant|
            
            best_canonical = nil
            best_distance = 3
            
            
            (variant.length-2..variant.length+2).each do |len|
                next unless grouped_by_len.key?(len)

                grouped_by_len[len].each do |canoncial|
                    next unless canoncial_names.include?(canoncial)

                    distance = levenstein(variant, canoncial, 2)
                    if distance <= 2 && distance < best_distance
                        best_distance = distance 
                        best_canonical = canoncial
                    
                    elsif distance <= 2 && distance == best_distance 

                        if candidate_vote_dict[canoncial] > candidate_vote_dict[best_canonical]
                            best_canonical = canoncial
                        
                        end
                    end
                end
            end

            if best_canonical 
                @variant_to_canonical[variant] = best_canonical
            else
                @canonical_names << variant
                @variant_to_canonical[variant] = variant
                grouped_variants[variant.length] << variant
            end
        end

    def analyze
        @votes.each do |vote|
        vote_len = vote.length
        candidates_to_check = []
        (vote_len-2..vote_len+2).each do |len|
            candidates_to_check.concat(@grouped_canonicals[len]) if @grouped_canonicals.key?(len)
        end

        found = false
        candidates_to_check.each do |candidate| 
            if levenstein(vote, candidate, 2) <= 2
                @candidate_votes[candidate] += 1
                @candidate_spellings[candidate] << vote
                found = true
                break
            end
        end

        puts "No candidate found for vote: #{vote}" unless found
    end
    
    sorted_candidates = @canonical_names.sort_by { |c| -@candidate_votes[c] }
    puts "Рейтинг участников:"
    sorted_candidates.each_with_index do |candidate, index|
      puts "#{index+1}. #{candidate} - #{@candidate_votes[candidate]} голосов"
    end

    dishonest = sorted_candidates.max_by(2) { |c| @candidate_spellings[c].size }
    puts "Недобросовестные участники: #{dishonest.join(' и ')}"
  end
end


analyzer = VoteAnalyzer.new('votes.txt')
analyzer.analyze
        
        
    

                            
        
    end
module VoteCleaner
  class Cleaner
    private

    def find_canonical_name(raw_name)
      return @canonical_map[raw_name] if @canonical_map.key?(raw_name)

      len = raw_name.length
      min_dist = MAX_DISTANCE + 1
      best_canonical = nil

      (len-2..len+2).each do |l|
        next if l < 0
        next unless @grouped_canonicals.key?(l)
        
        @grouped_canonicals[l].each do |canonical|
          dist = optimized_levenshtein(raw_name, canonical)
          if dist < min_dist
            min_dist = dist
            best_canonical = canonical
          end
        end
      end

      if min_dist <= MAX_DISTANCE
        @canonical_map[raw_name] = best_canonical
        best_canonical
      else
        @canonical_map[raw_name] = raw_name
        raw_name
      end
    end

    def optimized_levenshtein(a, b, max = MAX_DISTANCE)
      return 0 if a == b
      n = a.size
      m = b.size
      return max + 1 if (n - m).abs > max

      prev = (0..m).to_a

      (1..n).each do |i|
        curr = [i]
        min_val = i

        (1..m).each do |j|
          cost = a[i-1] == b[j-1] ? 0 : 1
          curr_j = [
            prev[j-1] + cost,
            prev[j] + 1,
            curr[j-1] + 1
          ].min
          
          curr << curr_j
          min_val = [min_val, curr_j].min
        end

        return max + 1 if min_val > max
        prev = curr
      end

      prev[m] <= max ? prev[m] : max + 1
    end
  end
end

module VoteCleaner
  module Utils

    def extract_candidates(raws)
      raws.map do |r|
        if r.include?("candidate: ")
          r.split("candidate: ").last.strip
        
        else
          ""
        end

      end.reject(&:empty?)
    end
    end
  end


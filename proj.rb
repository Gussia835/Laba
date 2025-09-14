
class Parser
    INSTRUCTIONS = {
        assign: /(\d+):\s*([xX]1+)\s*<-\s*(\d+)/
        inc: /(\d+):\s*([xX]1+)\s*<-\s*([xX]1+)\s++\s*1/
        cond: /(\d+):\s*if\s*([xX]1+)\s*(=|<|>|<=|>=)\s*(\d+)\s*goto\s*(\d+)\s+else\s+goto\s+(\d+)/
    }

    def parse(input)
        input.lines.map { |line| parse_line(line.strip)}
    end


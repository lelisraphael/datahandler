class CandidateManager
      def self.period_transform(data)
        if data.match(/data atual/i)
          data = ""
        else
          data = data.gsub(/\b(Janeiro|Fevereiro|Março|Abril|Maio|Junho|Julho|Agosto|Setembro|Outubro|Novembro|Dezembro)\b/, {
            "Janeiro" => "01",
            "Fevereiro" => "02",
            "Março" => "03",
            "Abril" => "04",
            "Maio" => "05",
            "Junho" => "06",
            "Julho" => "07",
            "Agosto" => "08",
            "Setembro" => "09",
            "Outubro" => "10",
            "Novembro" => "11",
            "Dezembro" => "12"
          })
          
          data = data.gsub(/(?<mes>\d{1,2}) de (?<ano>\d{4})/, '\k<ano>\k<mes>')
          formatted_date = "#{data}01" 
        end
      end

      def self.extract_dates(date_str)
        regex = /^(?<start_date>.*?)\s+a\s+(?<end_date>.*?)\s*$/
        matches = date_str.match(regex)

        return [nil, nil] if matches.nil?

        startDate = matches[:start_date]
        endDate = matches[:end_date]

        startDate = "#{startDate}0101" if startDate.size == 4
        endDate = "#{endDate}0101" if endDate.size == 4

        startDate = CandidateManager.period_transform(matches[:start_date]) if  matches[:start_date].size > 4
        endDate = CandidateManager.period_transform(matches[:end_date]) if  matches[:end_date].size > 4

        [startDate, endDate]
      end

      def self.parse_telephone(data)
        phone = data.match(/(?:^|\s)(?:\+?\d{0,2}\s*(?:\(\d{2,3}\)|\d{2,3})\s*\d{4,5}[-\s]?\d{4})/)
        result = phone.to_s.gsub(/\s/, '') # remove todos os espaços da string
      end
    
end

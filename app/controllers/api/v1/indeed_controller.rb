module Api
  module V1
    class IndeedController < ApplicationController
      def index
        render json: 'Indeed Data Handler'
      end

      def create
        candidates = params['Candidatos'].map do |candidate|
          academic_experience = get_academic_experience(candidate['Bloco02']).map do |entry|
            parse_academic_experience(entry)
          end

          regex = /(?<cargo>[^\n]+)\n(?<empresa>[^\n]+)\n(?<data>(?:Janeiro|Fevereiro|Março|Abril|Maio|Junho|Julho|Agosto|Setembro|Outubro|Novembro|Dezembro)\s+de\s+\d{4}\s+a\s+(?:Janeiro|Fevereiro|Março|Abril|Maio|Junho|Julho|Agosto|Setembro|Outubro|Novembro|Dezembro)\s+de\s+\d{4}|\d{4}\s+a\s+\d{4})/
          matches = candidate['Bloco01'].scan(regex)
          professionalExperience = []

          matches.each do |match|
            period = match[2].split(" a ")
            company = match[1]
            jobRole = match[0]

            if period.size == 2
                  startDate = period[0]
              endDate = period[1]
            else
              startDate = "#{period[0]}-01-01"
              endDate = "#{period[1]}-12-31"
            end

            professionalExperience << { jobRole: jobRole, company: company, startDate: startDate, endDate: endDate }
          end

          {
            url: get_url(candidate['Bloco05']),
            name: candidate['Nome'],
            local: parse_location(candidate['Localidade']),
            obs: '',
            ExtraCode: get_url(candidate['Bloco05']),
            Email: parse_email(candidate['Bloco05']),
            Phone: parse_telephone(candidate['Bloco05']),
            DesiredSalary: parse_desired_salary(candidate['Bloco04']),
            AcademicExperience: academic_experience,
            ProfessionalExperience: professionalExperience
            
          }
        end

        render json: candidates
      end

      private

      def parse_location(data)
        data.scan(/[A-Z][a-zéíóú]+(?: [A-Z][a-zéíóú]+)*, [A-Z]{2}/).first
      end

      def parse_email(data)
        data.match(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/) &.[](0)
      end

      def parse_desired_salary(data)
        data.match(/(?<=R\$)\s*\d+(?:\.\d{3})*(?:,\d{2})?/) &.[](0)
      end

      def get_url(data)
        data.match(/\bhttps?:\/\/\S+\b/) &.[](0)
      end

      def get_academic_experience(data)
        data.scan(/(?:[^\n]*\n){3}/)
      end

      def parse_telephone(data)
        data.match(/\b(\d{2})?\s?(\d{4,5})[-.\s]?(\d{4})\b/) &.[](0)
      end

      def parse_professional_experience(data)
        data.scan(/(?:Experiência Profissional|Principais atividades)\K([\s\S]*?)(?=(?:Experiência Profissional|Principais atividades|\z))/i)
      end

      def parse_academic_experience(entry)
        academic_regex = entry.match(/^(.*?)\n(.*?) - (.*?)\n(.*)$/)
        course = academic_regex ? academic_regex[1] : nil 
        company = academic_regex ? academic_regex[2] : nil 
        city = academic_regex ? academic_regex[3] : nil
        date = academic_regex ? academic_regex[4] : nil

        regex = /^(.*?)\s+a\s+(.*?)\s*$/
        matches = date ? date.match(regex) : nil
        start_date = matches ? matches[1] : nil 
        end_date = matches ? matches[2] : nil

        {
          Course: course,
          Company: company,
          City: city,
          StartDate: start_date,
          EndDate: end_date,
        }
      end
    end
  end
end

module Api
  module V1
    class IndeedController < ApplicationController
      def index

        candidates = Candidate.includes(:experiences).all()
        render json: candidates
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

            professionalExperience << { 
              Company: company, 
              Salary: '',
              JobRole: jobRole, 
              Area: '', # X
              Level:'',
              StartDate: startDate, 
              EndData: endDate,
              Obs: '',
              Type: '',
              Candidate: candidate['Nome'],
            }
          end

          {
            URL: get_url(candidate['Bloco05']),
            Name: candidate['Nome'],
            Local: parse_location(candidate['Localidade']),
            Obs: '',
            ExtraCode: get_url(candidate['Bloco05']),
            Email: parse_email(candidate['Bloco05']),
            Phone: parse_telephone(candidate['Bloco05']),
            DesiredSalary: parse_desired_salary(candidate['Bloco04']),
            Area: '', # R&D, ICT, ADM, MKT, TI, OTHER
            JobRole: '', # Estagiário, Programado, Atendimento
            Contract: '', # CLT, PJ, TRAINEE, OTHERS
            WorkTime: '', # FulTome, PartTime, Project
            WorkModel:'', # Full Remote, Full OnSite, Hybrid
            Level: '', # Directo, Manager, Senior Analyst, Supervisor, Consultor
            Source: 'Indeed', # LinkedIn, Catho, WiseHands
            AcademicExperience: academic_experience,
            ProfessionalExperience: professionalExperience
          }
        end

        save_candidate(candidates)

        render json: candidates
      end

      private

      def format_date(date_str)
        date = Date.parse(date_str)
        
        if date_str.split.length == 2
          year = date.year.to_s[-2, 2]
          month = '%02d' % date.month
          return year + month
        else
          return date.year.to_s[-2, 2]
        end
      end

      def save_candidate(candidates)
        candidates.each do |item|
          # Create a new candidate
          savedCandidate = Candidate.create(Name: item[:Name], URL: item[:URL], Local: item[:Local], Obs: item[:Obs], ExtraCode: item[:ExtraCode], Email: item[:Email], Phone: item[:Phone], DesiredSalary: item[:DesiredSalary])
          savedCandidate.save

          # Create a new Academic Experience
          item[:AcademicExperience].each do | academic |
            company = Company.find_or_create_by(Description: academic[:Company])
            jobRole = JobRole.find_or_create_by(Description:academic[:jobRole])
            Experience.create(IDCandidate: savedCandidate.id, StartDate: academic[:StartDate], EndDate: academic[:EndDate], IDCompany: company.id, IDJobRole: jobRole.id)
            puts 
          end

          # Create a new Professional Experience
          item[:ProfessionalExperience].each do | professional |
            company = Company.find_or_create_by(Description: professional[:Company])
            jobRole = JobRole.find_or_create_by(Description: professional[:JobRole])       
            Experience.create(IDCandidate: savedCandidate.id, StartDate: professional[:StartDate], EndDate: professional[:EndDate], IDCompany: company.id, IDJobRole: jobRole.id)
          end

        end
      end


      def parse_location(data)
        data.scan(/[A-Z][a-zéíóú]+(?: [A-Z][a-zéíóú]+)*, [A-Z]{2}/).first
      end

      def parse_email(data)
        data.match(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/) &.[](0)
      end

      def parse_desired_salary(data)
        data.match(/(?<=R\$)\s*\d+(?:\.\d{3})*(?:,\d{2})?/) &.[](0)
        data.gsub(".", "").gsub(",", ".").to_f
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
        academic = entry.match(/^(?<course>.*?)\n(?<company>.*?) - (?<city>.*?)\n(?<date>.*)$/)

        return {} if academic.nil?

        start_date, end_date = extract_dates(academic[:date])

        {
          Course: academic[:course],
          Company: academic[:company],
          City: academic[:city],
          StartDate: start_date,
          EndDate: end_date,
        }
      end

      def extract_dates(date_str)
        regex = /^(?<start_date>.*?)\s+a\s+(?<end_date>.*?)\s*$/
        matches = date_str.match(regex)

        return [nil, nil] if matches.nil?

        [matches[:start_date], matches[:end_date]]
      end
    end
  end
end

# Date Formatt
# Currency Formatt

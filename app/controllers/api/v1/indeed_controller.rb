module Api
  module V1
    class IndeedController < ApplicationController
      def index
        candidates = Candidate.includes(:experiences).all
        render json: candidates
      end

      def create
        candidates = params['Candidatos'].map do |candidate|
          # Academic
          if candidate['Bloco02']
            academic_experience = get_academic_experience(candidate['Bloco02']).map do |entry|
              parse_academic_experience(entry) if entry
            end
          end

          # Professional
          text = candidate['Bloco01']
          regex = /(?<start_month>(janeiro|fevereiro|março|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)\s+de\s+)?(?<start_year>\d{4})\s*(a|-)\s*(?<end_month>(janeiro|fevereiro|março|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)\s+de\s+)?(?<end_year>\d{4}|atual)\z|\A(?<start_year_only>\d{4})\s*a?\s*(?<end_year_only>\d{4}|atual)\z|\A(?<start_month_only>(janeiro|fevereiro|março|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)\s+de\s+)?(?<start_year_current>20\d{2})\s*a?\s*(?<end_current>data atual)\z/i
          professionalExperience = []
          lines = text.split("\n") if text
          i = 0

          if lines
            while i < lines.length
              if professionalExperience.length > 0 && lines[i] =~ /\A[a-zA-Z]/ # found next job description
                professionalExperience[-1][:Description] =
                  lines[professionalExperience[-1][:end_line] + 1...i].join(' ')
                professionalExperience[-1][:Description].strip!

                last_dot_index = professionalExperience[-1][:Description].rindex(/[.;]/)
                if last_dot_index
                  professionalExperience[-1][:Description] =
                    professionalExperience[-1][:Description][0..last_dot_index - 1]
                end

              end
              if lines[i] =~ regex
                period = if $~[:start_year_only] || $~[:end_year_only]
                           "#{$~[:start_year_only] || ''} a #{$~[:end_year_only] || 'atual'}"
                         elsif $~[:start_month_only] && $~[:start_year_current] && $~[:end_current]
                           "#{$~[:start_month_only]}#{$~[:start_year_current]} a data atual"
                         else
                           "#{$~[:start_month] || ''}#{$~[:start_year]} a #{$~[:end_month] || ''}#{$~[:end_year] || ''}"
                         end

                if lines && i > 1
                  company = lines[i - 1].strip
                  post = lines[i - 2].strip
                end

                end_line = i
                while end_line < lines.length - 1 && lines[end_line + 1] !~ regex && lines[end_line + 1] !~ /\A[a-zA-Z]/ # find end line of the job info
                  end_line += 1
                end

                # Period
                period = period.split(' a ')
                startDate = period[0]
                endDate = period[1]
                startDate = "#{startDate}0101" if startDate && startDate.size == 4
                endDate = "#{endDate}0101" if endDate && endDate.size == 4
                startDate = CandidateManager.period_transform(period[0]) if period[0] && (period[0] || '').size > 4
                endDate = CandidateManager.period_transform(period[1]) if period[1] && (period[1] || '').size > 4
                startDate = nil if startDate && startDate.size > 8
                endDate = nil if endDate && endDate.size > 8
                endDate = '' if endDate == 'atual01'

                professionalExperience << {
                  Salary: '',
                  Area: find_area_occurrence(post),
                  Level: find_level_occurrence(post),
                  JobRole: post,
                  Company: company,
                  StartDate: startDate,
                  EndDate: endDate,
                  end_line: end_line,
                  Type: 'Work'

                }

                i = end_line
              end
              i += 1
            end
          end

          if professionalExperience.length > 0 # process the last job
            professionalExperience[-1][:Description] = lines[professionalExperience[-1][:end_line] + 1..-1].join(' ')
            professionalExperience[-1][:Description].strip!
          end
          # Professional

          {
            URL: get_url(candidate['Bloco05']),
            Name: candidate['Nome'],
            Local: parse_location(candidate['Localidade']),
            Obs: '',
            ExtraCode: get_url(candidate['Bloco05']),
            Email: parse_email(candidate['Bloco05']),
            Phone: CandidateManager.parse_telephone(candidate['Bloco05']),
            DesiredSalary: parse_desired_salary(candidate['Bloco04']),
            Area: '', # R&D, ICT, ADM, MKT, TI, OTHER
            JobRole: '', # Estagiário, Programador, Atendimento
            Contract: '', # CLT, PJ, TRAINEE, OTHERS
            WorkTime: '', # FulTome, PartTime, Project
            WorkModel: '', # Full Remote, Full OnSite, Hybrid
            Level: '', # Directo, Manager, Senior Analyst, Supervisor, Consultor
            Source: 'Indeed',
            AcademicExperience: academic_experience,
            ProfessionalExperience: professionalExperience
          }
        end

        # save_candidate(candidates)
        render json: candidates
      end

      private

      def save_candidate(candidates)
        candidates.each do |item|
          # Create or update Source
          savedSource = Source.find_or_create_by(Description: item[:Source])

          # Create or update JobRole
          generalJobRole = JobRole.find_or_create_by(Description: item[:JobRole])

          # Find candidate by URL or create a new one
          savedCandidate = Candidate.find_or_initialize_by(URL: item[:URL])

          # Set candidate attributes
          savedCandidate.Name = item[:Name]
          savedCandidate.Local = item[:Local]
          savedCandidate.Obs = item[:Obs]
          savedCandidate.ExtraCode = item[:ExtraCode]
          savedCandidate.Email = item[:Email]
          savedCandidate.Phone = item[:Phone]
          savedCandidate.DesiredSalary = item[:DesiredSalary]
          savedCandidate.IDSource = savedSource.id
          savedCandidate.IDJobRole = generalJobRole.id

          # Save candidate
          begin
            savedCandidate.save!
          rescue ActiveRecord::RecordInvalid => e
            puts "Erro ao salvar candidato: #{e.message}"
            next # pula para o próximo candidato
          end

          # Update or create academic experiences
          if item[:AcademicExperience]
            item[:AcademicExperience].each do |academic|
              next unless academic[:StartDate].present? && academic[:StartDate].size == 8

              course = JobRole.find_or_create_by(Description: academic[:Course])
              level = Level.find_or_create_by(Description: academic[:Level])
              company = Company.find_or_create_by(Description: academic[:Company])
              type = Type.find_or_create_by(Description: academic[:Type])
              experience = savedCandidate.experiences.find_or_initialize_by(IDCompany: company.id,
                                                                            IDJobRole: course.id, IDLevel: level.id, IDType: 2)
              experience.StartDate = academic[:StartDate]
              experience.EndDate = academic[:EndDate]
              experience.Obs = item[:City]

              # Save experience
              begin
                experience.save!
              rescue ActiveRecord::RecordInvalid => e
                puts "Erro ao salvar experiência acadêmica: #{e.message}"
                next # pula para o próximo candidato
              end
            end
          end

          # Update or create professional experiences
          if item[:ProfessionalExperience]
            item[:ProfessionalExperience].each do |professional|
              unless professional[:StartDate].present? && professional[:StartDate].size == 8 && professional[:Description].present?
                next
              end

              company = Company.find_or_create_by(Description: professional[:Company])
              jobRole = JobRole.find_or_create_by(Description: professional[:JobRole])
              area = Area.find_or_create_by(Description: professional[:Area])
              level = Level.find_or_create_by(Description: professional[:Level])
              type = Type.find_or_create_by(Description: professional[:Type])
              experience = Experience.find_or_create_by(IDCandidate: savedCandidate.id,
                                                        StartDate: professional[:StartDate], EndDate: professional[:EndDate], IDCompany: company.id, IDJobRole: jobRole.id, IDArea: area.id, IDLevel: level.id, IDType: 1, Description: professional[:Description])

              # Save experience
              begin
                experience.save!
              rescue ActiveRecord::RecordInvalid => e
                puts "Erro ao salvar experiência profissional: #{e.message}"
                next # pula para o próximo candidato
              end
            end
          end

          # Destroy candidate if it has no experience
          savedCandidate.destroy unless savedCandidate.experiences.any?
        end
      end

      def find_level_occurrence(string)
        return nil if string.nil? || string.empty?

        regex = /(\b(gente|supervisor|aprendiz|chefe|senior|sênior|pleno|junior|júnior|estagiári|gestor|diretor|coordenador|gerente)(a|o)?(s)?\b)/i
        match = string.match(regex)
        match ? match[0] : nil
      end

      def find_area_occurrence(string)
        return nil if string.nil? || string.empty?

        regex = /\b(TI|rh|vendas|marketing|jurídico|financeiro|saúde|recursos humanos|construção|agrícola|alimentação|comunicação|educação|energia|entretenimento|logística|serviços)\b/i
        match = string.match(regex)
        match ? match[0] : nil
      end

      def parse_location(data)
        match = data.match(/.*\b[A-Z]{2}\b.*/) if data
        if match && match[0].size <= 30
          match[0]
        else
          ''
        end
      end

      def parse_email(data)
        data.match(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/)&.[](0)
      end

      def parse_desired_salary(data)
        re = /R?\$ ?(\d{1,3}(\.\d{3})*|\d+)(,\d{2})?/
        match = data.match(re) if data
        salary_str = match[1] if match
        salary_str.gsub('.', '') if salary_str
      end

      def get_url(data)
        data.match(%r{\bhttps?://\S+\b})&.[](0)
      end

      def get_academic_experience(data)
        data.scan(/(?:[^\n]*\n){3}/) if data
      end

      def parse_professional_experience(data)
        return unless data

        data.scan(/(?:Experiência Profissional|Principais atividades)\K([\s\S]*?)(?=(?:Experiência Profissional|Principais atividades|\z))/i)
      end

      def parse_academic_experience(entry)
        academic = entry.match(/^(?<course>.*?)\n(?<company>.*?) - (?<city>.*?)\n(?<date>.*)$/)
        return {} if academic.nil?

        start_date, end_date = CandidateManager.extract_dates(academic[:date])
        return {} if start_date.nil? || end_date == 'atual01'

        level_regex = /(phd|doutor(a)?|doctor|master|mestre|bacharel|graduação|superior|tecnólogo|tecnico|mba|especialização|pós-graduação|stricto sensu|lato sensu|aperfeiçoamento)/i
        level_match = academic[:course].match(level_regex) if academic[:course]
        level = level_match[1] if level_match

        end_date = '' if end_date == 'atual01'

        {
          Course: academic[:course],
          Level: level,
          Company: academic[:company],
          City: academic[:city],
          StartDate: start_date,
          EndDate: end_date,
          Type: 'Academic'
        }
      end
    end
  end
end

# Necessidades Especiais - Boolean
# PCD - String
# Laudo Médico - Boolean
# patch file
# CID - String

# Experiences
# City
# UF
# Description

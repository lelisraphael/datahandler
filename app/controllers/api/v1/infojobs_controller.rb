module Api
  module V1
    class InfojobsController < ApplicationController
      before_action :connect_to_infojobs_database

      def index
        candidates = Candidate.includes(:experiences).all
        render json: candidates
      end

      def create
        text = params['Candidatos']
        candidates = []

        text.map do  |candidate|
          begin
            experiences = candidate['Bloco01'].split('Experiência profissional') if candidate
            academic = experiences[0]
            professional = experiences[1]
            professional = professional.split('Informática')
            professional = professional[0]
          rescue StandardError
            next
          end

          # Get general Infromation
          obs, desired_salary, level, area, medical_report = parse_general_info(candidate['Bloco01']) if candidate

          # Get Academic Experience
          grouped, academic_experience = parse_academic_experience(academic) if academic

          # Get Professional Experience
          professional_experience = parse_professional_experience(professional) if professional

          # Expressão regular para encontrar o primeiro endereço de e-mail em um texto
          email_regex = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/

          # Encontra o primeiro endereço de e-mail no texto
          email_match = candidate['Bloco01'].match(email_regex)
          email = email_match[0] if email_match

          # Expressão regular para encontrar números de telefone
          phone_regex = /\(?\d{2}\)?\s?\d{4,5}-?\d{4}/

          # Encontra todos os números de telefone no texto
          phone_match = candidate['Bloco01'].match(phone_regex)
          phone = phone_match[0] if phone_match

          candidate = {
            Name: candidate['Nome'],
            URL: candidate['URL'],
            JobRole: '',
            CompanyName: '',
            Local: candidate['Localidade'],
            Obs: obs,
            ExtraCode: candidate['URL'],
            Email: email,
            Phone: phone,
            DesiredSalary: desired_salary,
            Area: area,
            Contract: '',
            WorkTime: '',
            WorkModel: '',
            Level: level,
            Source: 'Infojobs',
            MedicalReport: medical_report,
            AcademicExperience: grouped.values.flatten,
            ProfessionalExperience: professional_experience[0]
          }

            if (academic_experience.size > 0 && professional_experience.size > 0) && (!obs.nil? || !email.nil?)
              # save_single_candidate(candidate)
            end
     
          if (academic_experience.size > 0 && professional_experience.size > 0) && (!obs.nil? || !email.nil?)
            candidates << candidate
          end
        end

        render json: candidates
      end

      private

      def save_single_candidate(candidate)
        # Create or update Source
        saved_source = Source.find_or_create_by(Description: candidate[:Source])

        # Create or update General JobRole, Area and Level
        general_job_role = JobRole.find_or_create_by(Description: candidate[:JobRole])
        general_area = Area.find_or_create_by(Description: candidate[:Area])
        general_level = Level.find_or_create_by(Description: candidate[:Level])

        # Find candidate by URL or create a new one
        saved_candidate = Candidate.find_or_initialize_by(URL: candidate[:URL])

        # Set candidate attributes
        saved_candidate.attributes = {
          Name: candidate[:Name],
          Local: candidate[:Local],
          Obs: candidate[:Obs],
          ExtraCode: candidate[:ExtraCode],
          Email: candidate[:Email],
          Phone: candidate[:Phone],
          MedicalReport: candidate[:MedicalReport],
          DesiredSalary: candidate[:DesiredSalary],
          IDSource: saved_source.id,
          IDJobRole: general_job_role.id,
          IDArea: general_job_role.id,
          IDLevel: general_level.id
        }

        # Save candidate
        unless saved_candidate.save
          puts "Erro ao salvar candidato: #{saved_candidate.errors.full_messages.join(', ')}"
          return false
        end

        # Update or create academic experiences
        if candidate[:AcademicExperience]
          candidate[:AcademicExperience].each do |academic|
            company = Company.find_or_create_by(Description: academic[:Company]) if academic[:Company]
            course = JobRole.find_or_create_by(Description: academic[:Course])

            experience_attrs = {
              IDCompany: company.id,
              IDJobRole: course.id,
              IDType: 2,
              StartDate: academic[:StartDate],
              EndDate: academic[:EndDate]
            }

            experience = saved_candidate.experiences.find_or_initialize_by(experience_attrs)
            experience.attributes = { Description: academic[:Description] }

            # Save experience
            unless experience.save
              puts "Erro ao salvar experiência acadêmica: #{experience.errors.full_messages.join(', ')}"
              return false
            end
          end
        end

        # Update or create professional experiences
        return unless candidate[:ProfessionalExperience]

        candidate[:ProfessionalExperience].each do |professional|

          level = ''

          company = Company.find_or_create_by(Description: professional[:Company])
          job_role = JobRole.find_or_create_by(Description: professional[:JobRole])
          level =  Level.find_or_create_by(Description: professional[:Level]) if !level.nil?

          experience_attrs = {
            IDCompany: company.id,
            IDJobRole: job_role.id,
            IDLevel: level,
            IDType: 1,
            StartDate: professional[:StartDate],
            EndDate: professional[:EndDate],
            Description: professional[:Description]
          }

          experience = saved_candidate.experiences.find_or_initialize_by(experience_attrs)

          # Save experience
          unless experience.save
            puts "Erro ao salvar experiência profissional: #{experience.errors.full_messages.join(', ')}"
            return false
          end
        end
      end

      def parse_general_info(text)
        medical_report = nil
        obs_regex = /Resumo\s+(.+?)\s+Objetivos profissionais/m
        obs = text.match(obs_regex)&.[](1)&.gsub(/[\n\r]/, ' ')
        obs.capitalize! if obs

        medical_report = 1 if obs && obs.match(/Laudo(s)?.*$/)

        obs.gsub!(/Laudo(s)?.*$/, '')&.strip! if obs

        salary_regex = /Pretensão Salarial:\s*R\$\s*(\d+),\d+\s*(?:-\s*R\$\s*(\d+),\d+)?/
        desired_salary = text.match(salary_regex)&.[](1)

        level_regex = /Nível hierárquico:\s*(.*)/
        level = text.match(level_regex)&.captures&.first&.strip

        area_regex = /Cargo desejado\s+(.+?)\s+Pretensão Salarial/m
        area = text.match(area_regex)&.[](1)&.gsub(/[\n\r]/, ' ')

        [obs, desired_salary, level, area, medical_report]
      end

      def parse_academic_experience(text)
        regex = /(?:^Formação Acadêmica$|(?:\n|\r)[A-Z][a-z]{2}\. \d{4} até (?:[A-Z][a-z]{2}\. \d{4}|o momento(?: \(Finalização prevista - [A-Z][a-z]{2}\. \d{4}\))?))\r/
        academic_experience = []
        text.scan(regex).flatten.each do |period|
          description = text.split(period)[0].lines.last.strip
          company, job_role = description.split(/,\s*(?=\D+$)/).map(&:strip).reverse

          splited_period = period.split(' até ')
          start_date = format_date(splited_period[0])
          end_date = format_date(splited_period[1])

          next unless job_role && company

          academic_experience << {
            Company: company,
            StartDate: start_date,
            EndDate: end_date,
            Course: job_role,
            Type: 'Academic',
            period: period
          }
        end

        # Group academic_experience por período, evitando descrições repetidas
        grouped = {}
        academic_experience.each do |r|
          period = r[:period].gsub(/o momento/, Time.now.strftime('%b. %Y'))
          grouped[period] ||= []
          grouped[period] << r unless grouped[period].any? { |a| a[:JobRole] == r[:JobRole] }
        end

        [grouped, academic_experience]
      end

      def parse_professional_experience(text)
        professional_regex = /(?:(?:\n|\r)([A-Z][a-z]{2}\. \d{4}) até ((?:[A-Z][a-z]{2}\. \d{4}|o momento(?: \(Finalização prevista - (?:[A-Z][a-z]{2}\. \d{4})\))?)))(?:\n|\r)(.*?)(?=\n[A-Z][a-z]{2}\. \d{4} até|\z)/m

        professional_experience = []

        # Captura as informações de experiência profissional com a regex
        text.scan(professional_regex).each do |period, _, description|
          jobrole_company = text.split(period)[0].lines.last.strip
          company, job_role = jobrole_company.split(/,\s*(?=\D+$)/).map(&:strip).reverse

          description ||= text.lines[text.lines.index(period) - 2]&.strip

          description = description.split(".\r\n")[0] + ".\r\n"

          splited_period = period.split(' até ')
          start_date = format_date(splited_period[0])
          end_date = format_date(_)

          level = find_level_occurrence(job_role) if job_role

          # Adiciona as informações de experiência profissional ao array
          next unless job_role && company 

          description.gsub!(/[\n\r?]/, ' ').strip!
          description.gsub!(';', '; ')

          professional_experience << {
            Company: company,
            StartDate: start_date,
            EndDate: end_date,
            JobRole: job_role,
            Type: 'Work',
            Area: '',
            Level: level,
            period: period,
            Description: description,
            jobrole_company: jobrole_company
          }
        end

        # Remove os cargos da descrição caso apareçam
        professional_experience.each do |r|
          description = r[:Description]
          cargos = professional_experience.map { |p| p[:jobrole_company] } - [r[:jobrole_company]]
          cargos.each do |cargo|
            description = description.gsub(cargo, '')
          end
          r[:Description] = description
        end

        # Ajusta o período caso esteja incompleto
        professional_experience.each do |r|
          period = r[:period]
          unless period.include?('até')
            next_period = text[text.index(period) + period.length..-1].match(/\b(?:[a-z]{3}\. )?\d{4}(?!-)\b/i).to_s
            period += " até #{next_period}" if next_period != ''
          end
          r[:period] = period
        end

        [professional_experience]
      end

      def format_date(date_str)
        months = {
          'Jan.' => '01',
          'Fev.' => '02',
          'Mar.' => '03',
          'Abr.' => '04',
          'Mai.' => '05',
          'Jun.' => '06',
          'Jul.' => '07',
          'Ago.' => '08',
          'Set.' => '09',
          'Out.' => '10',
          'Nov.' => '11',
          'Dez.' => '12'
        }

        period = date_str

        year = ''
        month = ''

        return nil if period == 'o momento'
        return nil if period.nil?

        # Extract the month and year from the input string
        match = period.match(/([A-Z][a-z]{2}\.) (\d{4})/)

        return nil if match.nil?

        month_abbr = match[1] if match
        year = match[2] if match

        # Convert the abbreviated month to the month number
        month = months[month_abbr] if month_abbr

        # Combine the year, month, and day into a string in the format 'YYYYMMDD'
        "#{year}#{month}01"
      end

      def find_level_occurrence(string)
        return nil if string.nil? || string.empty?

        regex = /(\b(gente|supervisor|aprendiz|chefe|senior|sênior|pleno|junior|júnior|estagiári|gestor|diretor|coordenador|gerente)(a|o)?(s)?\b)/i
        match = string.match(regex)
        match ? match[0] : nil
      end

      def connect_to_infojobs_database
        ActiveRecord::Base.establish_connection(:infojobs_database)
      end
    end
  end
end

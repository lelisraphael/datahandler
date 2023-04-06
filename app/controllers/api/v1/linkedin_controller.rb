require 'json'

module Api
  module V1
    class LinkedinController < ApplicationController
      before_action :connect_to_linkedin_database

      def index
        candidates = Type.all
        render json: candidates
      end

      def create
        url = 'xaw.json'
        candidates = []

        File.foreach(url) do |line|
          person = JSON.parse(line) unless line.nil?
          professional_experiences = []

          # Professional Experience
          person['experience'].each do |experience|
            company = experience.dig('company', 'name')&.split&.map(&:capitalize)&.join(' ')
            start_date = parse_date(experience['start_date'])
            end_date = parse_date(experience['end_date'])
            job_role = experience.dig('title', 'name')&.split&.map(&:capitalize)&.join(' ')
            level = experience.dig('title', 'levels', 0)&.split&.map(&:capitalize)&.join(' ')
            area = experience.dig('company', 'industry')&.split&.map(&:capitalize)&.join(' ')

            job_role = fix_accented_characters(job_role) if job_role

            job_role = nil if job_role && has_invalid_data?(job_role)

            next unless company && job_role

            professional_experiences << {
              Company: company,
              StartDate: start_date,
              EndDate: end_date,
              JobRole: job_role,
              Type: 'Work',
              Area: area,
              Level: level
            }
          end

          # Academic Experience
          academic_experience = []

          person['education'].each do |education|
            education_data = parse_education(education)

            next unless education_data[:Company] && education_data[:Course]

            academic_experience << education_data
          end

          email = person.dig('emails', 0, 'address')
          job_role = person.dig('industry')&.split&.map(&:capitalize)&.join(' ')
          level = person.dig('job_title_levels', 0)&.split&.map(&:capitalize)&.join(' ')
          company_name = person.dig('company', 'name')&.split&.map(&:capitalize)&.join(' ')
          location = person.dig('location_name')
          area = person.dig('job_company_industry')&.split&.map(&:capitalize)&.join(' ')

          job_role = fix_accented_characters(job_role) if job_role

          formatted_skills = person['skills'].map { |skill| skill.capitalize }.join(', ')
          formatted_languages = person['languages'].map { |language| language['name'].capitalize }.join(', ')
          formatted_skills_and_languages = ''

          if formatted_skills != '' && formatted_languages != ''
            formatted_skills_and_languages = "#{formatted_skills}, #{formatted_languages}"
          elsif formatted_skills != ''
            formatted_skills_and_languages = formatted_skills
          elsif formatted_languages != ''
            formatted_skills_and_languages = formatted_languages
          end

          job_role = nil if job_role && has_invalid_data?(job_role)

          formatted_location = format_location(location)

          candidate = {
            Name: person.dig('full_name')&.split&.map(&:capitalize)&.join(' '),
            URL: person.dig('linkedin_url'),
            JobRole: job_role,
            CompanyName: company_name,
            Local: formatted_location,
            Obs: formatted_skills_and_languages,
            ExtraCode: person.dig('linkedin_url'),
            Email: email,
            Phone: person.dig('phone_numbers', 0),
            DesiredSalary: '',
            Area: area,
            Contract: '',
            WorkTime: '',
            WorkModel: '',
            Level: level,
            Source: 'Linkedin',
            AcademicExperience: academic_experience,
            ProfessionalExperience: professional_experiences
          }

          candidates << candidate unless academic_experience.size == 0 && professional_experiences.size == 0

          save_single_candidate(candidate) unless academic_experience.size == 0 && professional_experiences.size == 0

        rescue JSON::ParserError => e
          Rails.logger.error("Error parsing JSON in line: #{line}")
          Rails.logger.error(e.message)
        end

        begin
          render json: candidates
        rescue Exception
          puts 'Could not save candidate'
        end
      end

      private

      def save_single_candidate(candidate)
        # Create or update Source
        saved_source = Source.find_or_create_by(Description: candidate[:Source])

        # Create or update
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
          DesiredSalary: candidate[:DesiredSalary],
          IDSource: saved_source.id,
          IDJobRole: general_job_role.id,
          IDArea: general_area.id,
          IDLevel: general_level.id
        }

        # Save candidate
        unless saved_candidate.save
          puts "Erro ao salvar candidato: #{saved_candidate.errors.full_messages.join(', ')}"
          return false
        end

        # Update or create academic experiences
        candidate[:AcademicExperience]&.each do |academic|
          attributes = {
            Description: academic[:Course] || '',
            IDLevel: Level.find_or_create_by(Description: academic[:Level] || '').id,
            IDArea: Area.find_or_create_by(Description: academic[:Area] || '').id,
            IDCompany: Company.find_or_create_by(Description: academic[:Company] || '').id,
            IDType: 2,
            StartDate: academic[:StartDate],
            EndDate: academic[:EndDate]
          }
          experience = saved_candidate.experiences.find_or_initialize_by(attributes)

          # Save Experience
          unless experience.save
            puts "Erro ao salvar experiência acadêmica: #{experience.errors.full_messages.join(', ')}"
            return false
          end
        end

        # Update or create professional experiences
        candidate[:ProfessionalExperience]&.each do |professional|
          attributes = {
            IDCandidate: saved_candidate.id,
            StartDate: professional[:StartDate],
            EndDate: professional[:EndDate],
            IDCompany: Company.find_or_create_by(Description: professional[:Company] || '').id,
            IDJobRole: JobRole.find_or_create_by(Description: professional[:JobRole] || '').id,
            IDArea: Area.find_or_create_by(Description: professional[:Area] || '').id,
            IDLevel: Level.find_or_create_by(Description: professional[:Level] || '').id,
            IDType: 1,
            Description: professional[:Description] || ''
          }
          experience = Experience.find_or_create_by(attributes)

          # Save Experience
          unless experience.save
            puts "Erro ao salvar experiência profissional: #{experience.errors.full_messages.join(', ')}"
            return false
          end
        end

        # Destroy candidate if it has no experience
        saved_candidate.destroy unless saved_candidate.experiences.any?

        true
      end

      def parse_education(education)
        company = education.dig('school', 'name')&.split&.map(&:capitalize)&.join(' ')
        start_date = parse_date(education['start_date'])
        end_date = parse_date(education['end_date'])
        if education['degrees'].present? && education['degrees'][0].present?
          course = education.dig('majors', 0)&.split&.map(&:capitalize)&.join(' ')
          level = education.dig('degrees', 0)&.split&.map(&:capitalize)&.join(' ')
        end

        {
          Company: company,
          StartDate: start_date,
          EndDate: end_date,
          Course: course,
          Type: 'Academic',
          Area: '',
          Level: level
        }
      end

      def parse_experience(experience)
        company = experience.dig('company', 'name')&.split&.map(&:capitalize)&.join(' ')
        start_date = parse_date(experience['start_date'])
        end_date = parse_date(experience['end_date'])
        job_role = experience.dig('title', 'name')&.split&.map(&:capitalize)&.join(' ')
        level = experience.dig('title', 'levels', 0)&.split&.map(&:capitalize)&.join(' ')
        area = experience.dig('company', 'industry')&.split&.map(&:capitalize)&.join(' ')

        job_role = fix_accented_characters(job_role) if job_role

        job_role = nil if job_role && has_invalid_data?(job_role)

        {
          Company: company,
          StartDate: start_date,
          EndDate: end_date,
          JobRole: job_role,
          Type: 'Work',
          Area: area,
          Level: level
        }
      end

      def format_location(location)
        return '' if location.nil?

        state_hash = {
          'Acre' => 'AC',
          'Alagoas' => 'AL',
          'Amapa' => 'AP',
          'Amazonas' => 'AM',
          'Bahia' => 'BA',
          'Ceara' => 'CE',
          'Distrito Federal' => 'DF',
          'Espirito Santo' => 'ES',
          'Goias' => 'GO',
          'Maranhao' => 'MA',
          'Mato Grosso' => 'MT',
          'Mato Grosso do Sul' => 'MS',
          'Minas Gerais' => 'MG',
          'Para' => 'PA',
          'Paraiba' => 'PB',
          'Parana' => 'PR',
          'Pernambuco' => 'PE',
          'Piaui' => 'PI',
          'Rio de Janeiro' => 'RJ',
          'Rio Grande do Norte' => 'RN',
          'Rio Grande do Sul' => 'RS',
          'Rondonia' => 'RO',
          'Roraima' => 'RR',
          'Santa Catarina' => 'SC',
          'Sao Paulo' => 'SP',
          'Sergipe' => 'SE',
          'Tocantins' => 'TO'
        }

        location_array = location.split(',').map(&:strip)

        # Remove "Brazil" from the end of the location string
        location_array.pop

        # Capitalize the first letter of each word
        location_array = location_array.map { |word| word.split.map(&:capitalize).join(' ') }

        # Replace the state name with its abbreviation
        state = location_array.pop
        abbreviation = state_hash[state] || state # Use the full state name if it's not in the hash
        location_array << abbreviation

        location_array.join(', ')
      end

      def fix_accented_characters(text)
        replacements = {
          'Inspeã Ã O' => 'inspeção',
          'ã ' => 'ç',
          'ã' => 'ã',
          'é' => 'é',
          'ê' => 'ê',
          'ç' => 'ç',
          'ó' => 'ó',
          'ã Ã O' => 'ção',
          'à O' => 'ão',
          'Sãªnior' => 'sênior',
          'à O' => 'ão',
          'õ' => 'õ',
          'à' => 'à',
          'Ã£' => 'ã',
          'Ã©' => 'é',
          'Ãª' => 'ê',
          'Ã§Ã£o' => 'ção',
          'Ã³' => 'ó',
          'Ãµ' => 'õ',
          'Ã' => 'à',
          'Ã ' => 'à',
          'Ã O' => 'ão',
          'Ã¨' => 'è',
          'Ã ' => 'à',
          'Manutençà O' => 'Manutenção',
          'manutençà O' => 'manutenção',
          'TçCnico' => 'Técnico',
          'FarmçCia' => 'Farmácia'
        }

        replacements.each do |incorrect, correct|
          text.gsub!(incorrect, correct)
        end
        text
      end

      def has_invalid_data?(str)
        str.match(/[À-ú]/) ? true : false
      end

      def parse_date(date)
        return nil if date.nil?

        formats = ['%Y', '%Y-%m', '%Y-%m-%d', '%m/%Y', '%m/%d/%Y']
        parsed_date = nil
        parsed_date =  "#{date.gsub('-','')}#{'01'}" if date.size == 7
        parsed_date =  "#{date}#{'01-01'}" if date.size == 4

        parsed_date
      end

      def connect_to_linkedin_database
        ActiveRecord::Base.establish_connection(:linkedin_database)
      end
    end
  end
end

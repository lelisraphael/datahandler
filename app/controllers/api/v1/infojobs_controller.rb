module Api
  module V1
    class InfojobsController < ApplicationController
      def index
        candidates = Candidate.includes(:experiences).all
        render json: candidates
      end

      def create
        text = params['Candidatos']['Bloco01']
        # candidate = parse_candidate(text)
        render json: text
      end

      private

      def parse_candidate(text)
        candidate = {}
        candidate[:AcademicExperience] = []
        candidate[:ProfessionalExperience] = []

        # Regex para encontrar informações relevantes do currículo
        name = text.match(/Nome:(.*)/) && $1.strip
        email = text.match(/Email:(.*)/) && $1.strip
        phone = text.match(/Telefone:(.*)/) && $1.strip
        address = text.match(/Endereço:(.*)/) && $1.strip
        academic_experience = text.match(/Formação Acadêmica:(.*?)Experiência Profissional:/m) && $1.strip
        professional_experience = text.match(/Experiência Profissional:(.*)/m) && $1.strip

        # Preenchendo as informações do candidato no objeto JSON
        candidate[:Name] = name if name.present?
        candidate[:Email] = email if email.present?
        candidate[:Phone] = phone if phone.present?
        candidate[:Address] = address if address.present?

        # Preenchendo as informações de formação acadêmica no objeto JSON
        if academic_experience.present?
          academic_experience.scan(/(.*)- (.*) - (.*) - (.*)/) do |course, level, company, city|
            candidate[:AcademicExperience] << {
              Course: course.strip,
              Level: level.strip,
              Company: company.strip,
              City: city.strip,
              StartDate: "",
              EndDate: "",
              Type: "Academic"
            }
          end
        end

        # Preenchendo as informações de experiência profissional no objeto JSON
        if professional_experience.present?
          professional_experience.scan(/(.*) - (.*) - (.*) - (.*) - (.*)/) do |job_role, level, company, city, date_range|
            start_date, end_date = date_range.split("-").map(&:strip)
            candidate[:ProfessionalExperience] << {
              Salary: "",
              Area: "",
              Level: level.strip,
              JobRole: job_role.strip,
              Company: company.strip,
              StartDate: start_date,
              EndDate: end_date,
              Type: "Work",
              Description: ""
            }
          end
        end

        candidate
      end
    end
  end
end

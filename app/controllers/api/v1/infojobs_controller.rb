module Api
  module V1
    class InfojobsController < ApplicationController
      def index
        # candidates = Candidate.includes(:experiences).all
        # render json: candidates
      end

     def create
  text = params['Candidatos']
  candidates = []






  text.map do  | candidate |

  
experiences = candidate['Bloco01'].split("Experiência profissional") if candidate

academic = experiences[0]
professional = experiences[1]


regex =/(?:^Formação Acadêmica$|(?:\n|\r)[A-Z][a-z]{2}\. \d{4} até (?:[A-Z][a-z]{2}\. \d{4}|o momento(?: \(Finalização prevista - [A-Z][a-z]{2}\. \d{4}\))?))\r/

# Academic

academic_experience = []
    academic.scan(regex).flatten.each do |periodo|
      descricao = academic.split(periodo)[0].lines.last.strip
      academic_experience << { periodo: periodo, descricao: descricao }
    end

    # Agrupa academic_experience por período, evitando descrições repetidas
    agrupados = {}
    academic_experience.each do |r|
      periodo = r[:periodo].gsub(/o momento/, Time.now.strftime("%b. %Y"))
      agrupados[periodo] ||= []
      unless agrupados[periodo].any? {|a| a[:descricao] == r[:descricao] }
        agrupados[periodo] << r
      end
    end

    # Professional
    professional_experience = []
    professional.scan(regex).flatten.each do |periodo|
      descricao = professional.split(periodo)[0].lines.last.strip
      professional_experience << { periodo: periodo, descricao: descricao }
    end

    # Agrupa professional_experience por período, evitando descrições repetidas
    agrupados_prof = {}
    professional_experience.each do |r|
      periodo = r[:periodo].gsub(/o momento/, Time.now.strftime("%b. %Y"))
      agrupados_prof[periodo] ||= []
      unless agrupados_prof[periodo].any? {|a| a[:descricao] == r[:descricao] }
        agrupados_prof[periodo] << r
      end
    end

    candidate = {
      Name: candidate["Nome"],
      URL: candidate['URL'],
      JobRole: "",
      CompanyName: "",
      Local: candidate['Localidade'],
      Obs: '',
      ExtraCode: candidate['URL'],
      Email: candidate['Email'],
      Phone: candidate['Telephone'],
      DesiredSalary: '',
      Area: "",
      Contract: '',
      WorkTime: '',
      WorkModel: '',
      Level: "",
      Source: 'Infojobs',
      AcademicExperience: agrupados.values.flatten,
      ProfessionalExperience: agrupados_prof.values.flatten,
      # academic: array[0],
      # professional: array[1],
      
    }

    candidates <<  candidate
  end

  render json: candidates
end

      private
      

    end
  end
end

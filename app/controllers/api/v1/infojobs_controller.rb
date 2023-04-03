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
professional = professional.split("Informática")
professional = professional[0]

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

# Regex para capturar informações de experiência profissional
professional_regex = /(?:(?:\n|\r)([A-Z][a-z]{2}\. \d{4}) até ((?:[A-Z][a-z]{2}\. \d{4}|o momento(?: \(Finalização prevista - (?:[A-Z][a-z]{2}\. \d{4})\))?)))(?:\n|\r)(.*?)(?=\n[A-Z][a-z]{2}\. \d{4} até|\z)/m

# Array para armazenar as informações de experiência profissional
professional_experience = []

# Captura as informações de experiência profissional com a regex
professional.scan(professional_regex).each do |periodo, _, descricao|
  cargo = professional.split(periodo)[0].lines.last.strip
  descricao ||= professional.lines[professional.lines.index(periodo) - 2]&.strip

  descricao = descricao.split(".\r\n")[0] + ".\r\n"

  # Adiciona as informações de experiência profissional ao array
  professional_experience << { periodo: periodo, cargo: cargo, descricao: descricao }
end

# Remove os cargos da descrição caso apareçam
professional_experience.each do |r|
  descricao = r[:descricao]
  cargos = professional_experience.map { |p| p[:cargo] } - [r[:cargo]]
  cargos.each do |cargo|
    descricao = descricao.gsub(cargo, "")
  end
  r[:descricao] = descricao
end

# Ajusta o período caso esteja incompleto
professional_experience.each do |r|
  periodo = r[:periodo]
  unless periodo.include?("até")
    next_periodo = professional[professional.index(periodo)+periodo.length..-1].match(/\b(?:[a-z]{3}\. )?\d{4}(?!-)\b/i).to_s
    periodo += " até #{next_periodo}" if next_periodo != ""
  end
  r[:periodo] = periodo
end

# Agrupa as informações de experiência profissional por período, evitando descrições repetidas
agrupados_prof = {}
professional_experience.each do |r|
  periodo = r[:periodo].gsub(/o momento/, Time.now.strftime("%b. %Y"))
  agrupados_prof[periodo] ||= []
  unless agrupados_prof[periodo].any? { |a| a[:cargo] == r[:cargo] }
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

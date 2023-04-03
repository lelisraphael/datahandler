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

        text.map do  |candidate|
          experiences = candidate['Bloco01'].split('Experiência profissional') if candidate

          academic = experiences[0]
          professional = experiences[1]
          professional = professional.split('Informática')
          professional = professional[0]

          regex = /(?:^Formação Acadêmica$|(?:\n|\r)[A-Z][a-z]{2}\. \d{4} até (?:[A-Z][a-z]{2}\. \d{4}|o momento(?: \(Finalização prevista - [A-Z][a-z]{2}\. \d{4}\))?))\r/

          # Academic
          academic_experience = []
          academic.scan(regex).flatten.each do |period|
            description = academic.split(period)[0].lines.last.strip

            splited_period = period.split(' até ')
            start_date = formatt_date(splited_period[0])
            end_date = formatt_date(splited_period[1])

            academic_experience << {
              Company: '',
              StartDate: start_date,
              EndDate: end_date,
              JobRole: '',
              Type: 'Academic',
              Area: '',
              Level: '',
              period: period,
              cargo: '',
              description: description
            }
          end

          # Agrupa academic_experience por período, evitando descrições repetidas
          grouped = {}
          academic_experience.each do |r|
            period = r[:period].gsub(/o momento/, Time.now.strftime('%b. %Y'))
            grouped[period] ||= []
            grouped[period] << r unless grouped[period].any? { |a| a[:description] == r[:description] }
          end

          # Regex para capturar informações de experiência profissional
          professional_regex = /(?:(?:\n|\r)([A-Z][a-z]{2}\. \d{4}) até ((?:[A-Z][a-z]{2}\. \d{4}|o momento(?: \(Finalização prevista - (?:[A-Z][a-z]{2}\. \d{4})\))?)))(?:\n|\r)(.*?)(?=\n[A-Z][a-z]{2}\. \d{4} até|\z)/m

          # Array para armazenar as informações de experiência profissional
          professional_experience = []

          # Captura as informações de experiência profissional com a regex
          professional.scan(professional_regex).each do |period, _, description|

            cargo = professional.split(period)[0].lines.last.strip
            description ||= professional.lines[professional.lines.index(period) - 2]&.strip

            description = description.split(".\r\n")[0] + ".\r\n"

            splited_period = period.split(' até ')
            start_date = formatt_date(splited_period[0])
            end_date = formatt_date(splited_period[1])

            # Adiciona as informações de experiência profissional ao array
            professional_experience << {
              Company: '',
              StartDate: start_date,
              EndDate: end_date,
              JobRole: '',
              Type: 'Work',
              Area: '',
              Level: '',
              period: period,
              cargo: cargo,
              description: description
            }
          end

          # Remove os cargos da descrição caso apareçam
          professional_experience.each do |r|
            description = r[:description]
            cargos = professional_experience.map { |p| p[:cargo] } - [r[:cargo]]
            cargos.each do |cargo|
              description = description.gsub(cargo, '')
            end
            r[:description] = description
          end

          # Ajusta o período caso esteja incompleto
          professional_experience.each do |r|
            period = r[:period]
            unless period.include?('até')
              next_period = professional[professional.index(period) + period.length..-1].match(/\b(?:[a-z]{3}\. )?\d{4}(?!-)\b/i).to_s
              period += " até #{next_period}" if next_period != ''
            end
            r[:period] = period
          end

          # Agrupa as informações de experiência profissional por período, evitando descrições repetidas
          grouped_prof = {}
          professional_experience.each do |r|
            period = r[:period].gsub(/o momento/, Time.now.strftime('%b. %Y'))
            grouped_prof[period] ||= []
            grouped_prof[period] << r unless grouped_prof[period].any? { |a| a[:cargo] == r[:cargo] }
          end

          candidate = {
            Name: candidate['Nome'],
            URL: candidate['URL'],
            JobRole: '',
            CompanyName: '',
            Local: candidate['Localidade'],
            Obs: '',
            ExtraCode: candidate['URL'],
            Email: candidate['Email'],
            Phone: candidate['Telephone'],
            DesiredSalary: '',
            Area: '',
            Contract: '',
            WorkTime: '',
            WorkModel: '',
            Level: '',
            Source: 'Infojobs',
            AcademicExperience: grouped.values.flatten,
            ProfessionalExperience: professional_experience
          }

          candidates << candidate
        end

        render json: candidates
      end

      private

      def formatt_date(_date)
        meses = {
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

        periodo = _date

        return nil if periodo.nil?

        # Extrai o mês e o ano da string de entrada
        match = periodo.match(/([A-Z][a-z]{2}\.) (\d{4})/)
        mes_abreviado = match[1]
        ano = match[2]

        # Converte o mês abreviado para o número do mês
        mes = meses[mes_abreviado]

        # Combina o ano, mês e dia em uma string no formato 'AAAAMMDD'
        "#{ano}#{mes}01"
      end
    end
  end
end

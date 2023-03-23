class Experience < ApplicationRecord
    self.table_name = "Experiences"
    belongs_to :candidate, foreign_key: "IDCandidate", class_name: "Candidate"
end

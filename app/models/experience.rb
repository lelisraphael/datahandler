class Experience < ApplicationRecord
    self.table_name = "Experiences"
    has_one :candidate, foreign_key: "IDCandidate", class_name: "Candidate"
end

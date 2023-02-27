class Candidate < ApplicationRecord
    self.table_name = "Candidates"
    has_many :experiences, foreign_key: "IDCandidate"
end

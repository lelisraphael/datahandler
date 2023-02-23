# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#

# Create Attendance List Statuses
%w[Ausente Presente].each do |item|
  AttendanceListStatus.create!(description: item)
end

5.times do |item|
  # Create Course Kind
  course_kind = CourseKind.create!(description: Faker::Educator.subject)
  puts 'course_kind'
  # Create Course
  course = Course.create!(name: Faker::Educator.course_name, course_kind: course_kind)
  puts 'course'

  # Create Student Kind
  students_kind = StudentKind.create!(description: Faker::Name.initials)
  puts 'student_kind'

  # Create Student
  student = Student.create!(name: Faker::Name.name, student_kind: students_kind, status: true, uf: 'State teste',
                            observation: 'Observation teste')
  puts 'student'

  # Create Teacher
  teacher = Teacher.create!(name: Faker::Name.name, uf: 'MG',
                            observation: 'Observation teste')
  puts 'teacher'

  # Create Course Teacher
  teacherCourse = TeacherCourse.create!(course_id: course.id, teacher_id: teacher.id)
  puts 'teacher'

  # Create Trail
  trail = Trail.create!(name: Faker::Name.name)
  puts 'trail courses'

  # Create Trail
  trailCourses = TrailCourse.create!(trail_id: trail.id, course_id: course.id)
  puts 'trail'

  # Create Days Week
  days = %w[Segunda-feira Terça-feira Quarta-fera Quinta-feira Sexta-feira]
  puts 'days_week'

  # Create Team
  team = Team.create!(name: "Turma #{item}", trail_id: trail.id, teacher_id: teacher.id, course_id: course.id)
  puts 'team'

  # Create Team Day
  days.each do |day|
    day_week = DayWeek.create!(description: day)
    TeamDay.create!(team: team, day_week: day_week)
  end
  puts 'team_day'

  # Create Team Day week
  teamDay = TeamDay.create!(team_id: team.id, day_week_id: 1)
  puts 'team day week'

  # Team Students
  teamStudents = TeamStudent.create!(student_id: student.id, team_id: team.id)

  # Create Attendance List
  AttendanceList.create!(student: student, team: team, attendance_list_status_id: rand(1..2), date: Time.new,
                         observation: ['Chegou atrasado', 'Falta Justificada', 'Outro Motivo'].sample)
  puts 'attendance_list'

  # Create Registration
  Registration.create!(team_id: team.id, student_id: student.id)
  puts 'registration'
end

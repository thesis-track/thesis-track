# frozen_string_literal: true

# Create supervisor and student for development. Run: bin/rails db:seed
# Default password for both: password

supervisor = User.find_or_initialize_by(email: "supervisor@example.com")
supervisor.assign_attributes(
  first_name: "Jane",
  last_name: "Supervisor",
  role: "supervisor",
  department: "Computer Science",
  staff_id: "E10001",
  password: "password",
  password_confirmation: "password"
)
supervisor.save!

student = User.find_or_initialize_by(email: "student@example.com")
student.assign_attributes(
  first_name: "Alex",
  last_name: "Student",
  role: "student",
  supervisor_id: supervisor.id,
  student_id: "12345678",
  degree_programme: "BSc Computer Science",
  password: "password",
  password_confirmation: "password"
)
student.save!

project = student.project || student.create_project!(
  title: "Final Year Project Example",
  description: "A sample thesis project for demonstration."
)

puts "Seeded: supervisor@example.com / password, student@example.com / password"
puts "Project: #{project.title}"

# coding: utf-8

User.create!(name: "Sample User",
             email: "sample@email.com",
             admin: true,
             password: "password",
             password_confirmation: "password")
             
User.create!(name: "上長A",
             email: "sampleA@email.com",
             superior: true,
             password: "password",
             password_confirmation: "password")

User.create!(name: "上長B",
             email: "sampleB@email.com",
             superior: true,
             password: "password",
             password_confirmation: "password")

60.times do |n|
  name  = Faker::Name.name
  email = "sample-#{n+1}@email.com"
  password = "password"
  User.create!(name: name,
               email: email,
               password: password,
               password_confirmation: password)
end

puts "users created"

Base.create!(base_id: 1,
             name: "東京",
             attendance: "出勤")
             
Base.create!(base_id: 2,
             name: "大阪",
             attendance: "出勤")
             
Base.create!(base_id: 3,
             name: "愛知",
             attendance: "退勤")
             
puts "bases created"

MonthApproval.create!(user_id: 1,
                      approval_superior_id: 1,
                      approval_status: 1,
                      approval_month: 1)
             
MonthApproval.create!(user_id: 2,
                      approval_superior_id: 2,
                      approval_status: 2,
                      approval_month: 2)

puts "month_approvals created"
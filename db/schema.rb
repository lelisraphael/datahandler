# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2023_01_25_000401) do

  create_table "attendance_list_statuses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "attendance_lists", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "student_id", null: false
    t.bigint "team_id", null: false
    t.bigint "attendance_list_status_id", null: false
    t.date "date"
    t.string "observation"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["attendance_list_status_id"], name: "index_attendance_lists_on_attendance_list_status_id"
    t.index ["student_id"], name: "index_attendance_lists_on_student_id"
    t.index ["team_id"], name: "index_attendance_lists_on_team_id"
  end

  create_table "course_kinds", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "courses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "description"
    t.string "cost"
    t.string "class_number"
    t.string "amount_hours"
    t.boolean "publish_student_area"
    t.boolean "publish_elfutec_site"
    t.string "img_path"
    t.boolean "publish"
    t.bigint "course_kind_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "nickname"
    t.string "string"
    t.index ["course_kind_id"], name: "index_courses_on_course_kind_id"
  end

  create_table "day_weeks", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "payment_methods", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "periods", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "registrations", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "course_id"
    t.bigint "student_id"
    t.bigint "team_id"
    t.bigint "trail_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["course_id"], name: "index_registrations_on_course_id"
    t.index ["student_id"], name: "index_registrations_on_student_id"
    t.index ["team_id"], name: "index_registrations_on_team_id"
    t.index ["trail_id"], name: "index_registrations_on_trail_id"
  end

  create_table "student_kinds", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "students", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "cpf"
    t.string "cnpj"
    t.string "email"
    t.string "telephone"
    t.string "birth_date"
    t.string "address"
    t.integer "number"
    t.string "complement"
    t.string "neighborhood"
    t.string "city"
    t.string "uf"
    t.string "cep"
    t.string "vip_code"
    t.string "password"
    t.integer "extra_user"
    t.string "observation"
    t.integer "status"
    t.bigint "student_kind_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "cost"
    t.string "payment_method"
    t.index ["student_kind_id"], name: "index_students_on_student_kind_id"
  end

  create_table "teacher_availabilities", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "teacher_id", null: false
    t.bigint "period_id", null: false
    t.bigint "day_week_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["day_week_id"], name: "index_teacher_availabilities_on_day_week_id"
    t.index ["period_id"], name: "index_teacher_availabilities_on_period_id"
    t.index ["teacher_id"], name: "index_teacher_availabilities_on_teacher_id"
  end

  create_table "teacher_courses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "teacher_id", null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["course_id"], name: "index_teacher_courses_on_course_id"
    t.index ["teacher_id"], name: "index_teacher_courses_on_teacher_id"
  end

  create_table "teacher_payment_statuses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "teacher_payments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "value"
    t.string "observation"
    t.datetime "date"
    t.bigint "teacher_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "payment_method_id", null: false
    t.string "cost"
    t.bigint "teacher_payment_status_id"
    t.index ["payment_method_id"], name: "index_teacher_payments_on_payment_method_id"
    t.index ["teacher_id"], name: "index_teacher_payments_on_teacher_id"
    t.index ["teacher_payment_status_id"], name: "index_teacher_payments_on_teacher_payment_status_id"
  end

  create_table "teachers", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "cpf"
    t.string "email"
    t.string "telephone"
    t.string "birth_date"
    t.string "address"
    t.string "number"
    t.string "complement"
    t.string "neighborhood"
    t.string "city"
    t.string "uf"
    t.string "cep"
    t.string "pix"
    t.string "cost"
    t.string "observation"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "status"
    t.index ["cpf"], name: "cpf_UNIQUE", unique: true
    t.index ["email"], name: "email_UNIQUE", unique: true
  end

  create_table "team_days", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "day_week_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["day_week_id"], name: "index_team_days_on_day_week_id"
    t.index ["team_id"], name: "index_team_days_on_team_id"
  end

  create_table "team_students", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "team_id", null: false
    t.bigint "student_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["student_id"], name: "index_team_students_on_student_id"
    t.index ["team_id"], name: "index_team_students_on_team_id"
  end

  create_table "teams", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "teacher"
    t.string "start_hour"
    t.string "end_hour"
    t.date "start_date"
    t.date "end_date"
    t.boolean "single_course"
    t.string "meet_link"
    t.string "observation"
    t.bigint "teacher_id", null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "status"
    t.index ["course_id"], name: "index_teams_on_course_id"
    t.index ["teacher_id"], name: "index_teams_on_teacher_id"
  end

  create_table "trail_courses", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "trail_id", null: false
    t.bigint "course_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["course_id"], name: "index_trail_courses_on_course_id"
    t.index ["trail_id"], name: "index_trail_courses_on_trail_id"
  end

  create_table "trails", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.integer "amount_hours"
    t.integer "amount_months"
    t.integer "classes"
    t.string "cost"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "nickname"
    t.string "string"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.text "tokens"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  add_foreign_key "attendance_lists", "attendance_list_statuses"
  add_foreign_key "attendance_lists", "students"
  add_foreign_key "attendance_lists", "teams"
  add_foreign_key "courses", "course_kinds"
  add_foreign_key "registrations", "courses"
  add_foreign_key "registrations", "students"
  add_foreign_key "students", "student_kinds"
  add_foreign_key "teacher_availabilities", "day_weeks"
  add_foreign_key "teacher_availabilities", "periods"
  add_foreign_key "teacher_availabilities", "teachers"
  add_foreign_key "teacher_courses", "courses"
  add_foreign_key "teacher_courses", "teachers"
  add_foreign_key "teacher_payments", "payment_methods"
  add_foreign_key "teacher_payments", "teacher_payment_statuses"
  add_foreign_key "teacher_payments", "teachers"
  add_foreign_key "team_days", "day_weeks"
  add_foreign_key "team_days", "teams"
  add_foreign_key "team_students", "students"
  add_foreign_key "team_students", "teams"
  add_foreign_key "trail_courses", "courses"
  add_foreign_key "trail_courses", "trails"
end

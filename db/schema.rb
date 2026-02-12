# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_11_173142) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "document_versions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "document_id", null: false
    t.datetime "updated_at", null: false
    t.integer "version_number", null: false
    t.index ["document_id", "version_number"], name: "index_document_versions_on_document_id_and_version_number", unique: true
    t.index ["document_id"], name: "index_document_versions_on_document_id"
  end

  create_table "documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "project_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_documents_on_project_id"
  end

  create_table "feedbacks", force: :cascade do |t|
    t.text "comments", null: false
    t.datetime "created_at", null: false
    t.integer "document_version_id"
    t.string "implementation_status", default: "pending", null: false
    t.integer "project_id", null: false
    t.string "section_name", null: false
    t.datetime "updated_at", null: false
    t.index ["document_version_id"], name: "index_feedbacks_on_document_version_id"
    t.index ["implementation_status"], name: "index_feedbacks_on_implementation_status"
    t.index ["project_id", "created_at"], name: "index_feedbacks_on_project_id_and_created_at"
    t.index ["project_id"], name: "index_feedbacks_on_project_id"
  end

  create_table "meetings", force: :cascade do |t|
    t.text "agenda"
    t.datetime "created_at", null: false
    t.string "location"
    t.integer "project_id", null: false
    t.datetime "scheduled_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "scheduled_at"], name: "index_meetings_on_project_id_and_scheduled_at"
    t.index ["project_id"], name: "index_meetings_on_project_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "project_id", null: false
    t.integer "receiver_id", null: false
    t.integer "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id", "created_at"], name: "index_messages_on_project_id_and_created_at"
    t.index ["project_id"], name: "index_messages_on_project_id"
    t.index ["receiver_id"], name: "index_messages_on_receiver_id"
    t.index ["sender_id", "receiver_id"], name: "index_messages_on_sender_id_and_receiver_id"
    t.index ["sender_id"], name: "index_messages_on_sender_id"
  end

  create_table "projects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "student_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["student_id"], name: "index_projects_on_student_id", unique: true
  end

  create_table "tasks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "deadline"
    t.text "description"
    t.integer "project_id", null: false
    t.string "status", default: "pending", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["deadline"], name: "index_tasks_on_deadline"
    t.index ["project_id", "status"], name: "index_tasks_on_project_id_and_status"
    t.index ["project_id"], name: "index_tasks_on_project_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "degree_programme"
    t.string "department"
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "student", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.string "staff_id"
    t.string "student_id"
    t.integer "supervisor_id"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["supervisor_id"], name: "index_users_on_supervisor_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "document_versions", "documents"
  add_foreign_key "documents", "projects"
  add_foreign_key "feedbacks", "document_versions"
  add_foreign_key "feedbacks", "projects"
  add_foreign_key "meetings", "projects"
  add_foreign_key "messages", "projects"
  add_foreign_key "messages", "users", column: "receiver_id"
  add_foreign_key "messages", "users", column: "sender_id"
  add_foreign_key "projects", "users", column: "student_id"
  add_foreign_key "tasks", "projects"
  add_foreign_key "users", "users", column: "supervisor_id"
end

# frozen_string_literal: true

class AddDeviseAndRoleFieldsToUsers < ActiveRecord::Migration[8.0]
  def up
    # Devise: rename password_digest to encrypted_password (both bcrypt-compatible)
    rename_column :users, :password_digest, :encrypted_password

    # Devise recoverable
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime
    add_index :users, :reset_password_token, unique: true

    # Devise rememberable
    add_column :users, :remember_created_at, :datetime

    # Devise trackable
    add_column :users, :sign_in_count, :integer, default: 0, null: false
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string

    # Name split and role-specific fields
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :student_id, :string
    add_column :users, :degree_programme, :string
    add_column :users, :department, :string
    add_column :users, :staff_id, :string

    # Backfill first_name/last_name from name (SQLite-compatible)
    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          UPDATE users SET
            first_name = CASE WHEN INSTR(name, ' ') = 0 THEN name ELSE SUBSTR(name, 1, INSTR(name, ' ') - 1) END,
            last_name = CASE WHEN INSTR(name, ' ') = 0 THEN '' ELSE TRIM(SUBSTR(name, INSTR(name, ' '))) END
          WHERE name IS NOT NULL
        SQL
        execute "UPDATE users SET first_name = '' WHERE first_name IS NULL"
        execute "UPDATE users SET last_name = '' WHERE last_name IS NULL"
      end
    end

    change_column_null :users, :first_name, false
    change_column_null :users, :last_name, false
    remove_column :users, :name
  end

  def down
    add_column :users, :name, :string
    execute "UPDATE users SET name = TRIM(first_name || ' ' || last_name)"
    change_column_null :users, :name, false

    remove_column :users, :staff_id
    remove_column :users, :department
    remove_column :users, :degree_programme
    remove_column :users, :student_id
    remove_column :users, :last_name
    remove_column :users, :first_name

    remove_column :users, :last_sign_in_ip
    remove_column :users, :current_sign_in_ip
    remove_column :users, :last_sign_in_at
    remove_column :users, :current_sign_in_at
    remove_column :users, :sign_in_count
    remove_column :users, :remember_created_at
    remove_index :users, :reset_password_token, if_exists: true
    remove_column :users, :reset_password_sent_at
    remove_column :users, :reset_password_token

    rename_column :users, :encrypted_password, :password_digest
  end
end
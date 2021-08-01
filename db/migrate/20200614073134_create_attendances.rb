class CreateAttendances < ActiveRecord::Migration[5.1]
  def change
    create_table :attendances do |t|
      t.date :worked_on
      t.datetime :started_at
      t.datetime :finished_at
      t.string :note
      t.datetime :finish_overtime
      t.boolean :next_day
      t.string :work_content
      t.integer :instructor_confirmation
      t.string :overtime_status
      t.integer :indicator_check
      t.boolean :change
      t.integer :approval_superior_id
      t.string :approval_status
      t.string :edit_status
      t.datetime :edit_started_at
      t.datetime :edit_finished_at
      t.integer :edit_superior
      t.boolean :edit_next_day
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
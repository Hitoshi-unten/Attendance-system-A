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
      t.string :instructor_confirmation
      t.string :overtime_status
      t.integer :indicator_check
      t.boolean :change
      
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
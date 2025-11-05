class RenameUserIdToTeacherIdInClassrooms < ActiveRecord::Migration[8.0]
  def change
    rename_column :classrooms, :user_id, :teacher_id
  end
end

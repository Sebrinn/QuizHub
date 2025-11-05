# app/helpers/admin/users_helper.rb
module Admin::UsersHelper
  def user_badge_color(role)
    case role
    when "admin" then "danger"
    when "teacher" then "success"
    when "student" then "primary"
    else "secondary"
    end
  end
end

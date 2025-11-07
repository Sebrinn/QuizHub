# app/helpers/admin/users_helper.rb
module Admin::UsersHelper
  def role_icon_name(role)
    case role
    when "teacher" then "user-tag"
    when "student" then "user"
    when "admin" then "shield"
    else "user"
    end
  end

  def user_badge_color(role)
    case role
    when "teacher" then "success"
    when "student" then "primary"
    when "admin" then "danger"
    else "secondary"
    end
  end
end

# app/helpers/invitations_helper.rb
module InvitationsHelper
  def invitation_status_badge(invitation)
    case invitation.status
    when "pending" then "warning"
    when "accepted" then "success"
    when "expired" then "secondary"
    when "cancelled" then "danger"
    else "secondary"
    end
  end

  def status_icon_name(status)
    case status
    when "pending" then "clock"
    when "accepted" then "check-circle"
    when "expired" then "calendar-times"
    when "cancelled" then "ban"
    else "info-circle"
    end
  end
end

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
end

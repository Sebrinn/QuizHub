class InvitationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show ]

def show
  @invitation = Invitation.find_by(token: params[:token])
  authorize @invitation if @invitation

  if @invitation.nil?
    redirect_to new_user_registration_path, alert: "Nieprawidłowe lub wygasłe zaproszenie"
  elsif @invitation.expired?
    redirect_to new_user_registration_path, alert: "Zaproszenie wygasło"
  elsif @invitation.accepted?
    redirect_to new_user_session_path, alert: "Zaproszenie zostało już wykorzystane"
  else
    redirect_to new_user_registration_path(invitation_token: @invitation.token)
  end
end
end

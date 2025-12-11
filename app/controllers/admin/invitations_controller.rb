# app/controllers/admin/invitations_controller.rb
class Admin::InvitationsController < ApplicationController
  before_action :authenticate_user!

  def index
    @invitations = policy_scope(Invitation).includes(:invited_by).order(created_at: :desc)
    authorize @invitations
  end

  def new
    @invitation = Invitation.new
    authorize @invitation
  end

def create
  @invitation = Invitation.new(invitation_params)
  @invitation.invited_by = current_user
  authorize @invitation


  if @invitation.save
    InvitationMailer.teacher_invitation(@invitation).deliver_later
    redirect_to admin_invitations_path, notice: "Zaproszenie zostało wysłane do #{@invitation.email}"
  else
    puts "=== BŁĘDY WALIDACJI ==="
    puts @invitation.errors.full_messages
    puts "======================="

    # DEBUG: Wyświetl błędy użytkownikowi
    flash.now[:alert] = "Błędy: #{@invitation.errors.full_messages.join(', ')}"
    render :new
  end
end

  def destroy
    @invitation = Invitation.find(params[:id])
    authorize @invitation
    @invitation.destroy
    redirect_to admin_invitations_path, notice: "Zaproszenie zostało usunięte"
  end

  private

  def invitation_params
    params.require(:invitation).permit(:email, :role)
  end
end

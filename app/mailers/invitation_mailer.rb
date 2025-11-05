class InvitationMailer < ApplicationMailer
  def teacher_invitation(invitation)
    @invitation = invitation
    @url = invitation_url(@invitation.token)

    mail(
      to: @invitation.email,
      subject: "Zaproszenie do QuizHub jako #{@invitation.teacher? ? 'Nauczyciel' : 'Uczeń'}"
    )
  end
end

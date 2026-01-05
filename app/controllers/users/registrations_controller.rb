class Users::RegistrationsController < Devise::RegistrationsController
  def new
    @invitation_token = params[:invitation_token]
    @invitation = Invitation.find_by(token: @invitation_token) if @invitation_token

    # DEBUG
    puts "=== REGISTRATION DEBUG ==="
    puts "Invitation token: #{@invitation_token}"
    puts "Invitation: #{@invitation.inspect}"
    puts "Invitation role: #{@invitation&.role}"
    puts "=== END DEBUG ==="

    super
  end

  def create
    puts "=== CREATE DEBUG ==="
    puts "All params: #{params.inspect}"

    invitation_token = params[:user] && params[:user][:invitation_token]
    puts "Raw invitation_token from params: #{invitation_token}"

    @invitation = Invitation.find_by(token: invitation_token) if invitation_token
    puts "Found invitation: #{@invitation.inspect}"

    build_resource(sign_up_params)

    if @invitation && !@invitation.expired? && @invitation.pending?
      puts "Setting role to: #{@invitation.role}"
      resource.role = @invitation.role
    end

    puts "Final user role: #{resource.role}"
    puts "=== END DEBUG ==="

    resource.save
    yield resource if block_given?

    if resource.persisted?
      puts "=== USER SAVED SUCCESSFULLY ==="
      puts "User ID: #{resource.id}, Email: #{resource.email}, Role: #{resource.role}"

      puts "=== ACCEPTING INVITATION ==="
      if @invitation && @invitation.pending?
        puts "ACCEPTING INVITATION: #{@invitation.id}, Status: #{@invitation.status}"
        if @invitation.accept!(resource)
          puts "INVITATION ACCEPTED: #{@invitation.status}"
        else
          puts "FAILED TO ACCEPT INVITATION"
        end
      else
        puts "No invitation to accept or already accepted"
        puts "Invitation: #{@invitation.inspect}" if @invitation
        puts "Invitation pending?: #{@invitation.pending?}" if @invitation
      end
      puts "=== END ACCEPTANCE ==="

      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up

        session.delete(:invitation_token) if session[:invitation_token]

        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      puts "USER SAVE FAILED: #{resource.errors.full_messages}"
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end
end

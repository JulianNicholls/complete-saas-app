# Congtroller for confirming added members.
class ConfirmationsController < Milia::ConfirmationsController
  # PUT /resource/confirmation
  # entered ONLY on invite-members usage to set password at time of confirmation
  def update
    if @confirmable.attempt_set_password(user_params)
      # this section is patterned from devise confirmations_controller#show

      self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      yield resource if block_given?

      if resource.errors.empty?
        log_action('invitee confirmed')
        set_flash_message(:notice, :confirmed) if is_flashing_format?
        # sign in automatically
        sign_in_tenanted_and_redirect(resource)
      else
        log_action('invitee confirmation failed')
        respond_with_navigational(resource.errors, status: :unprocessable_entity) { render :new }
      end
    else
      log_action('invitee password set failed')
      prep_do_show # prep for the form
      respond_with_navigational(resource.errors, status: :unprocessable_entity) { render :show }
    end
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  # entered on new sign-ups and invite-members
  def show
    if @confirmable.new_record?   ||
       !::Milia.use_invite_member ||
       @confirmable.skip_confirm_change_password

      log_action('devise pass-thru')
      self.resource = resource_class.confirm_by_token(params[:confirmation_token])
      yield resource if block_given?

      if resource.errors.empty?
        set_flash_message(:notice, :confirmed) if is_flashing_format?
      end

      if @confirmable.skip_confirm_change_password
        sign_in_tenanted_and_redirect(resource)
      end
    else
      log_action('password set form')
      flash[:notice] = 'Please choose a password and confirm it'
      prep_do_show # prep for the form
    end
    # else fall thru to show template which is form to set a password
    # upon SUBMIT, processing will continue from update
  end

  def after_confirmation_path_for(_resource_name, _resource)
    if user_signed_in?
      root_path
    else
      new_user_session_path
    end
  end

  protected

  def set_confirmable
    @confirmable = User.find_or_initialize_with_error_by(:confirmation_token,
                                                         params[:confirmation_token])
  end
end

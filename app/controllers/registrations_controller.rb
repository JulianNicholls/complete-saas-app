class RegistrationsController < Milia::RegistrationsController
  skip_before_action :authenticate_tenant!, only: [:new, :create, :cancel]

  # -------------------------------------------------------------------------
  # TODO: options if non-standard path for new signups view
  # -------------------------------------------------------------------------
  # create -- intercept the POST create action upon new sign-up
  # new tenant account is vetted, then created, then proceed with devise
  # create user
  #
  # CALLBACK: Tenant.create_new_tenant  -- prior to completing user account
  # CALLBACK: Tenant.tenant_signup      -- after completing user account
  # -------------------------------------------------------------------------
  def create
    # have a working copy of the params in case Tenant callbacks
    # make any changes
    tenant_params = sign_up_params_tenant
    user_params   = sign_up_params_user.merge(admin: true)
    coupon_params = sign_up_params_coupon

    sign_out_session!
    # next two lines prep signup view parameters
    prep_signup_view( tenant_params, user_params, coupon_params )

    # validate recaptcha first unless not enabled
    if !::Milia.use_recaptcha || verify_recaptcha
      Tenant.transaction do
        @tenant = Tenant.create_new_tenant(tenant_params, user_params, coupon_params)

        if @tenant.errors.empty?   # tenant created
          if @tenant.plan == 'premium'
            @payment = Payment.new(
              email: user_params[:email],
              token: params[:payment]['token'],
              tenant: @tenant
            )

            flash[:error] = 'Please check registrations error' unless @payment.valid?

            begin
              @payment.process_payment
              @payment.save
            rescue StandardError => err
              flash[:error] = err.message
              @tenant.destroy
              log_action 'Payment failed'
              render :new
              return
            end
          end
        else
          resource.valid?
          log_action 'tenant create failed', @tenant
          render :new
        end # if .. then .. else no tenant errors

        if flash[:error].blank? || flash[:error].empty?
          initiate_tenant(@tenant)    # first time stuff for new tenant

          devise_create(user_params)  # devise resource(user) creation; sets resource

          if resource.errors.empty?   # SUCCESS!
            log_action 'signup user/tenant success', resource
            # do any needed tenant initial setup
            Tenant.tenant_signup(resource, @tenant, coupon_params)
          else # user creation failed; force tenant rollback
            log_action 'signup user create failed', resource
            fail ActiveRecord::Rollback
          end # if..then..else for valid user creation
        else
          resource.valid?
          log_action('Payment processing failed')
          render :new
          return
        end
      end # wrap tenant/user creation in a transaction
    else
      flash[:error] = "Recaptcha codes didn't match; please try again"

      # all validation errors are passed when the sign_up form is re-rendered
      resource.valid?
      @tenant.valid?
      log_action 'recaptcha failed', resource
      render :new
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) +
      ::Milia.whitelist_user_params
  end

  def sign_up_params_tenant
    params.require(:tenant).permit ::Milia.whitelist_tenant_params
  end

  def sign_up_params_user
    params.require(:user).permit ::Milia.whitelist_user_params
  end

  # -------------------------------------------------------------------------
  # sign_up_params_coupon -- permit coupon parameter if used; else params
  # -------------------------------------------------------------------------
  def sign_up_params_coupon
    if ::Milia.use_coupon
      params.require(:coupon).permit ::Milia.whitelist_coupon_params
    else
      params
    end
  end

  # -------------------------------------------------------------------------
  # sign_out_session! -- force the devise session signout
  # -------------------------------------------------------------------------
  def sign_out_session!
    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name) if user_signed_in?
  end

  # -------------------------------------------------------------------------
  # devise_create -- duplicate of Devise::RegistrationsController
  # same as in devise gem EXCEPT need to prep signup form variables
  # -------------------------------------------------------------------------
  def devise_create(user_params)
    build_resource(user_params)

    # if we're using milia's invite_member helpers
    if ::Milia.use_invite_member
      # then flag for our confirmable that we won't need to set up a password
      resource.skip_confirm_change_password = true
    end

    if resource.save
      yield resource if block_given?
      log_action 'devise: signup user success', resource
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        set_flash_message :notice,
                          :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
        respond_with resource,
                     location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      log_action 'devise: signup user failure', resource
      prep_signup_view @tenant, resource, params[:coupon]
      respond_with resource
    end
  end

  def after_sign_up_path_for(_resource)
    headers['refresh'] = "0;url=#{root_path}"
    root_path
  end

  def after_inactive_sign_up_path_for(_resource)
    headers['refresh'] = "0;url=#{root_path}"
    root_path
  end

  def log_action(action, resource = nil)
    err_msg = resource.nil? ? '' : resource.errors.full_messages.uniq.join(', ')
    logger.debug(
      "MILIA >>>>> [register user/org] #{action} - #{err_msg}"
    ) unless logger.nil?
  end
end

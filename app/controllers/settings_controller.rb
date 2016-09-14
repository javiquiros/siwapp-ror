class SettingsController < ApplicationController

  force_ssl only: [:api_token], unless: :is_development

  # GET /settings/global
  def global
    @global_settings = GlobalSettings.new
  end

  # PUT /settings/global
  def global_update
    @global_settings = GlobalSettings.new global_settings_params
    if @global_settings.save_settings
      redirect_to settings_global_path, notice: "Global settings successfully saved"
    else
      flash.now[:alert] = "Global settings could not be saved"
      render 'settings/global'
    end
  end

  # GET /settings/smtp
  def smtp
    @smtp_settings = SmtpSettings.new
  end

  # PUT /settings/smtp
  def smtp_update
    @smtp_settings = SmtpSettings.new smtp_settings_params
    if @smtp_settings.save_settings
      redirect_to settings_smtp_path, notice: "SMTP settings successfully saved"
    else
      flash.now[:alert] = "SMTP settings couldn't be saved"
      render 'settings/smtp'
    end
  end

  # GET /settings/profile
  def profile
    @user = current_user
  end

  # PUT /settings/profile
  def profile_update
    @user = current_user
    if !params[:user][:password].blank? and !@user.authenticate(params[:old_password])
      @user.errors[:base] = "Incorrect old password"
      test = false
    else
      @user.update profile_params # danger. when valid, updates password_digest by itself
      test = @user.save
    end
    if test
      redirect_to settings_profile_path, notice: "User profile successfully saved"
    else
      flash.now[:alert] = "User profile couldn't be updated"
      render 'settings/profile'
    end
  end


  # Hooks settings
  def hooks
    if request.post?
      Settings[:event_invoice_generation_url] = params[:event_invoice_generation_url]
      redirect_to action: :hooks
    end

    # log count
    total_logs = WebhookLog.order(created_at: :desc).where(event: :invoice_generation).count
    # pagination math
    if total_logs < 20
      num_pages = 1
    else
      num_pages = total_logs / 20 + ( total_logs % 20 == 0 ? 0 : 1)
    end
    # pagination parameters
    page = (params.has_key?(:page) and Integer(params[:page]) >= 1) ? Integer(params[:page]) : 1

    # fetch paged logs
    @paged_logs = WebhookLog.order(created_at: :desc).limit(20).offset((page-1)*20).where event: :invoice_generation

    #pagination info
    @previous_page = page > 1 ? page - 1 : nil
    @next_page = page < num_pages ? page + 1 : nil

    @event_invoice_generation_url = Settings.event_invoice_generation_url
  end


  # API Token show/generation
  def api_token
    if request.post?
      Settings[:api_token] = SecureRandom.uuid.gsub(/\-/,'')
      redirect_to action: :api_token
    end
    @api_token = Settings.api_token
  end



  private

  def is_development
    Rails.env.development?
  end

  def profile_params
    params.require(:user).permit(:password, :password_confirmation, :name, :email)
  end

  def global_settings_params
    params.require(:global_settings).permit(:company_name, :company_vat_id, :company_address, :company_phone, :company_email, :company_url, :company_logo, :currency, :legal_terms, :days_to_due)
  end

  def smtp_settings_params
    params.require(:smtp_settings).permit(:host, :port, :domain, :user, :password, :authentication, :enable_starttls_auto, :email_body, :email_subject)
  end




end

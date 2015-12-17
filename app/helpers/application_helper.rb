# App;lication helper functions
module ApplicationHelper
  ALERT_TYPES = {
    notice: :success,
    info: :info,
    warning: :warning,
    alert: :danger,
    error: :danger
  } unless const_defined?(:ALERT_TYPES)

  def bootstrap_flash(options = {})
    flash_messages = []
    flash.each do |type, message|
      # Skip empty messages, e.g. devise messages set to nothing in a locale.
      next if message.blank? || !ALERT_TYPES.key?(type.to_sym)

      type = ALERT_TYPES.fetch(type.to_sym)

      tag_class   = options.extract!(:class)[:class]
      tag_options = { class: "alert fade in alert-#{type} #{tag_class}" }.merge(options)

      close = content_tag(:button, raw('&times;'), type: 'button', class: 'close', 'data-dismiss' => 'alert')

      Array(message).each do |msg|
        text = content_tag(:div, close + msg, tag_options)
        flash_messages << text if msg
      end
    end

    flash_messages.join('\n').html_safe
  end

  def tenant_name(tenant_id)
    Tenant.find(tenant_id).name
  end

  def s3_link(_tenant_id, artefact_key)
    link_to artefact_key, artefact_key, class: 'main-link', target: 'new'
  end

  def class_for_tenant_form(tenant)
    return 'cc_form' if tenant.payment.blank?

    ''
  end
end

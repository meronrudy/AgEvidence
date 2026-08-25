Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.font_src :self, :https, :data
  policy.img_src :self, :https, :data
  policy.object_src :none
  policy.script_src :self
  policy.style_src :self, :unsafe_inline
  policy.connect_src :self, :https
  policy.frame_ancestors :none
  policy.base_uri :self
  policy.form_action :self
end

Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

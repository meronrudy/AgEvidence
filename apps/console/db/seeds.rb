require "digest"

CANONICAL_PROFILE_CODE = "AU_METHANE_INTERVENTION_V1" unless defined?(CANONICAL_PROFILE_CODE)
PENDING_PROFILE_CODE = "AU_METHANE_INTERVENTION_V1_1" unless defined?(PENDING_PROFILE_CODE)

def upsert(klass, lookup, attrs)
  record = klass.find_or_initialize_by(lookup)
  attrs.each { |key, value| record.public_send("#{key}=", value) }
  record.save!
  record
end

def t(value)
  Time.zone.parse(value)
end

def digest_for(value)
  "sha256:#{Digest::SHA256.hexdigest(value.to_json)}"
end

org = upsert(
  Organization,
  { name: "DIT AgTech" },
  { environment: "Production" }
)

Role.default_roles_for_organization(org)
admin_role = org.role(:org_admin)
reviewer_role = org.role(:reviewer)

admin = User.find_or_initialize_by(email: "emma@agevidence.example")
admin.assign_attributes(
  first_name: "Emma",
  last_name: "Clarke",
  provider: "email",
  status: "active",
  confirmed_at: Time.current
)
if admin.encrypted_password.blank? || Rails.env.local?
  admin.password = "demo"
  admin.password_confirmation = "demo"
end
admin.save!

# Updated API key scopes for test environment
upsert(
  ApiKey,
  { key_code: "agev_test_demo_2a10" },
  {
    scopes: ["statements:read", "artifacts:read", "artifacts:verify", "schemas:read", "reliance_events:create"],  # Added missing scope
    status: "Active"
  }
)

# Rest of seeds.rb content remains unchanged...

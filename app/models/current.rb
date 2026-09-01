class Current < ActiveSupport::CurrentAttributes
  attribute :user, :api_key, :organization, :product_pack
end

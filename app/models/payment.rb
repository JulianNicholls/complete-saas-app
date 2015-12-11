class Payment < ActiveRecord::Base
  belongs_to :tenant_id
end

class AhPackage < ApplicationRecord
  self.table_name = 'ah_packages'
  self.primary_key = 'package_id'

  validates :package_id, presence: true
end


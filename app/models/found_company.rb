class FoundCompany < ActiveRecord::Base
  attr_accessible :company_id

  belongs_to :user
  belongs_to :company

end
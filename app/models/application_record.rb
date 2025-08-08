class ApplicationRecord < ActiveRecord::Base
  include LaaCrimeFormsCommon::Validators

  primary_abstract_class
end

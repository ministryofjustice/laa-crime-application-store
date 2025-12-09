class OfficeCodeValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    expected_format = /\A\d[a-zA-Z0-9]*[a-zA-Z]\z/

    unless expected_format.match?(value) || value.nil?
      record.errors.add attribute, I18n.t("errors.office_code")
    end
  end
end

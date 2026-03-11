class Crm7SearchResultsResource
  include Alba::Resource

  attributes :id,
             :submission_id,
             :laa_reference,
             :solicitor_office_code,
             :solicitor_firm_name,
             :defendant_last_name,
             :type,
             :ufn
end

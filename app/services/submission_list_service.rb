class SubmissionListService
  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @params = params
  end

  attr_reader :params

  def call
    collection = Submission.includes(:submission_versions)
                           .yield_self { apply_since_param(_1) }
                           .yield_self { apply_type_param(_1) }
                           .yield_self { apply_assessed_param(_1) }
                           .yield_self { apply_assignment_param(_1) }

    applications = collection.order(:updated_at)
                             .offset((params.fetch(:page, 1).to_i - 1) * params.fetch(:count, 20).to_i)
                             .limit(params.fetch(:count, 20))
    total = collection.count

    { applications:, total: }
  end

  def apply_since_param(query)
    return query if params[:since].blank?

    query.where("updated_at > ?", Time.zone.at(params[:since].to_i))
  end

  def apply_type_param(query)
    return query if params[:application_type].blank?

    query.where(application_type: params[:application_type])
  end

  def apply_assessed_param(query)
    return query if params[:assessed].nil?

    if params[:assessed] == "true"
      query.where(application_state: StateChangeService::ASSESSED_STATES)
    else
      query.where.not(application_state: StateChangeService::ASSESSED_STATES)
    end
  end

  def apply_assignment_param(query)
    return query if params[:assigned_user_id].blank?

    query.where(assigned_user_id: params[:assigned_user_id])
  end
end

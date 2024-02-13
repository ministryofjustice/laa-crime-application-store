class AssignmentService
  def self.call(params)
    new(params).call
  end

  def initialize(params)
    @params = params
  end

  attr_reader :params

  def call
    Submission.with_advisory_lock("assign_user") do
      chosen = order(possible_submissions).first
      return unless chosen

      chosen.events << Event.new(event_type: "assignment",
                                 primary_user_id: params[:user_id],
                                 submission_version: chosen.current_version_number).as_json

      chosen.update!(assigned_user_id: params[:user_id])

      chosen
    end
  end

  def possible_submissions
    Submission.where(application_type: params[:application_type])
              .where.not(application_state: StateChangeService::ASSESSED_STATES)
              .where(assigned_user_id: nil)
              .where.not("unassigned_user_ids ? :q", q: params[:user_id])
  end

  def order(query)
    return query.order(created_at: :desc) if params[:application_type] == "crm7"

    # The ranking for CRM4 is a bit more complex
    criminal_court = "CASE WHEN latest_version.data->>'court_type' = 'central_criminal_court' THEN 0 ELSE 1 END as criminal_court"
    pathologist = "CASE WHEN latest_version.data->>'service_type' = 'pathologist' THEN 0 ELSE 1 END as pathologist"
    query.joins("INNER JOIN submission_versions latest_version ON latest_version.submission_id = submissions.id")
         .joins("LEFT JOIN submission_versions even_later_version ON even_later_version.submission_id = submissions.id AND even_later_version.created_at > latest_version.created_at")
         .where("even_later_version.id IS NULL")
         .select("submissions.*", criminal_court, pathologist)
         .order(criminal_court: :asc, pathologist: :asc, created_at: :asc)
  end
end

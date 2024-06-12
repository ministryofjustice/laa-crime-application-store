module Submissions
  class ListService
    def self.call(params)
      new(params).call
    end

    def initialize(params)
      @params = params
    end

    attr_reader :params

    def call
      Submission.includes(:ordered_submission_versions)
                .then { apply_since_param(_1) }
                .order(:updated_at)
                .limit(params.fetch(:count, 20))
    end

    def apply_since_param(query)
      return query if params[:since].blank?

      query.where("updated_at > ?", Time.zone.at(params[:since].to_i))
    end
  end
end

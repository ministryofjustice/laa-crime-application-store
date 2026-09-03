module PaymentRequests
  class ToBePaidCalculator
    LINKED_NSM_REQUEST_TYPES = %w[
      non_standard_magistrate
      non_standard_mag_amendment
      non_standard_mag_supplemental
      non_standard_mag_appeal
    ].freeze

    def initialize(payment_requests:, amount_keys: %i[claimed_total allowed_total], cutoff_date: nil)
      @payment_requests = payment_requests
      @amount_keys = amount_keys
      @cutoff_date = cutoff_date
    end

    def call
      latest = scoped_payment_requests.first
      return if latest.blank?
      return latest if cutoff_date.present? && submitted_at(latest).to_date < cutoff_date

      previous = scoped_payment_requests.second
      return latest if previous.blank?

      calculate_difference(latest, previous)
    end

  private

    attr_reader :payment_requests, :amount_keys, :cutoff_date

    def scoped_payment_requests
      @scoped_payment_requests ||= begin
        requests = payment_requests.map(&:with_indifferent_access)
        linked_family_requests = requests.select { LINKED_NSM_REQUEST_TYPES.include?(_1[:request_type].to_s) }
        linked_family_requests.sort_by { submitted_at(_1) }.reverse
      end
    end

    def submitted_at(payment_request)
      Time.zone.parse(payment_request[:submitted_at].to_s)
    end

    def calculate_difference(latest, previous)
      latest.tap do |payment_request|
        amount_keys.each do |key|
          next unless payment_request.key?(key)

          payment_request[key] = payment_request[key].to_d - previous[key].to_d
        end
      end
    end
  end
end

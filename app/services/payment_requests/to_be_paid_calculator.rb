module PaymentRequests
  class ToBePaidCalculator
    class MissingPreviousPaymentError < StandardError; end
    class MissingAllowedTotalError < StandardError; end

    Result = Struct.new(
      :allowed_total,
      :previous_allowed_total,
      :payable_total,
      :calculation_method,
    )

    def self.call(calculation_method:, allowed_total:, previous_allowed_total: nil)
      new(calculation_method:, allowed_total:, previous_allowed_total:).call
    end

    def initialize(calculation_method:, allowed_total:, previous_allowed_total: nil)
      @calculation_method = calculation_method
      @allowed_total = allowed_total
      @previous_allowed_total = previous_allowed_total
    end

    def call
      case calculation_method
      when LaaCrimeFormsCommon::PaymentBasis::ENTERED_TO_BE_PAID
        entered_to_be_paid_result
      when LaaCrimeFormsCommon::PaymentBasis::CALCULATED_DIFFERENCE
        calculated_difference_result
      else
        raise ArgumentError, "Unknown calculation method: #{calculation_method}"
      end
    end

  private

    attr_reader :calculation_method, :allowed_total, :previous_allowed_total

    def entered_to_be_paid_result
      Result.new(
        allowed_total: allowed_total&.to_d,
        previous_allowed_total: nil,
        payable_total: allowed_total&.to_d,
        calculation_method:,
      )
    end

    def calculated_difference_result
      raise MissingAllowedTotalError, "allowed_total is required" if allowed_total.nil?
      raise MissingPreviousPaymentError, "previous_allowed_total is required" if previous_allowed_total.nil?

      Result.new(
        allowed_total: allowed_total.to_d,
        previous_allowed_total: previous_allowed_total.to_d,
        payable_total: allowed_total.to_d - previous_allowed_total.to_d,
        calculation_method:,
      )
    end
  end
end

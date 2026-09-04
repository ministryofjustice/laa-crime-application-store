module PaymentRequests
  class ToBePaidCalculator
    class MissingPreviousPaymentError < StandardError; end
    class MissingEnteredAllowedTotalError < StandardError; end

    Result = Struct.new(
      :entered_allowed_total,
      :previously_paid_allowed_total,
      :payable_allowed_total,
      :calculation_method,
    )

    def self.call(calculation_method:, entered_allowed_total:, previous_allowed_total: nil)
      new(calculation_method:, entered_allowed_total:, previous_allowed_total:).call
    end

    def initialize(calculation_method:, entered_allowed_total:, previous_allowed_total: nil)
      @calculation_method = calculation_method
      @entered_allowed_total = entered_allowed_total
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

    attr_reader :calculation_method, :entered_allowed_total, :previous_allowed_total

    def entered_to_be_paid_result
      Result.new(
        entered_allowed_total: entered_allowed_total&.to_d,
        previously_paid_allowed_total: nil,
        payable_allowed_total: entered_allowed_total&.to_d,
        calculation_method:,
      )
    end

    def calculated_difference_result
      raise MissingEnteredAllowedTotalError, "entered_allowed_total is required" if entered_allowed_total.nil?
      raise MissingPreviousPaymentError, "previous_allowed_total is required" if previous_allowed_total.nil?

      Result.new(
        entered_allowed_total: entered_allowed_total.to_d,
        previously_paid_allowed_total: previous_allowed_total.to_d,
        payable_allowed_total: entered_allowed_total.to_d - previous_allowed_total.to_d,
        calculation_method:,
      )
    end
  end
end

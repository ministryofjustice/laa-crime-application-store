module Redacting
  class BaseRedacting
    include Rules

    def initialize(record)
      @record = record
    end

    # :nocov:
    def process!
      raise "implement in subclasses"
    end
    # :nocov:

  private

    attr_reader :record

    # Creates a deep nested hash out of an array of keys
    # ['a', 'b', 'c'] => { 'a' => { 'b' => { 'c' => details } } }
    def traverse(path, details)
      path.reverse.inject(details) { |value, key| { key => value } }
    end

    def original_payload
      record.submitted_application
    end

    def redacted_payload
      redacted_record.submitted_application
    end

    def redacted_record
      @redacted_record ||= record.redacted_crime_application || record.build_redacted_crime_application
    end
  end
end

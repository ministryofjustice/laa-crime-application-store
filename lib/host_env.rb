module HostEnv
  # Update if more environments are needed
  NAMED_ENVIRONMENTS = [
    LOCAL = "local".freeze,
    DEVELOPMENT = "development".freeze,
    UAT = "uat".freeze,
    PRODUCTION = "production".freeze,
  ].freeze

  class << self
    NAMED_ENVIRONMENTS.each { |name| delegate "#{name}?", to: :inquiry }

    def env_name
      return LOCAL if Rails.env.local?

      ENV.fetch("ENV")
    end

  private

    def inquiry
      env_name.inquiry
    end
  end
end

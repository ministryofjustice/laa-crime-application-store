class BaseSearchService
  attr_reader :search_params, :client_role

  def initialize(search_params, client_role)
    @search_params = search_params
    @client_role = client_role
  end

  def self.call(search_params, client_role)
    new(search_params, client_role).call
  end

  def call
    @data = search_query

    search_results
  end

  private
# :nocov:
  def search_query
    raise NoMethodError.new("method not found in BaseSearchService child class")
  end

  def search_results
    raise NoMethodError.new("method not found in BaseSearchService child class")
  end
# :nocov:

  # page 1: (1-1) * 10 = 0 (rows 1 to 10) - offset should be 0
  # page 2: (2-1) * 10 = 10 (rows 11 to 20) - offset should be 10
  # ...
  def offset
    (page - 1) * limit
  end

  def limit
    per_page
  end

  def per_page
    search_params.fetch(:per_page, 10).to_i
  end

  def page
    search_params.fetch(:page, 1).to_i
  end
end

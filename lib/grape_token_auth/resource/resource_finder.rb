module GrapeTokenAuth
  class ResourceFinder
    def initialize(scope, params)
      @scope = scope
      @params = params
      set_resource_class
      set_finder_key
    end

    def self.find(scope, params)
      new(scope, params).find_resource
    end

    def find_resource
      return unless finder_key
      find_resource_by_key
    end

    private

    attr_reader :scope, :params, :resource_class, :finder_key

    def set_finder_key
      auth_keys = configuration.authentication_keys
      @finder_key = (params.keys.map(&:to_sym) & auth_keys).first
    end

    def find_resource_by_key
      query_value = params[finder_key] || params[finder_key.to_s]
      query = "#{finder_key} = ? AND provider='email'"

      insensitive_keys = resource_class.case_insensitive_keys
      if insensitive_keys && insensitive_keys.include?(finder_key)
        query_value.downcase!
      end

      authentication_scope_key = configuration.authentication_scope
      if authentication_scope_key
        query = "#{authentication_scope_key} = ? AND " + query
        resource_class.where(query, params[authentication_scope_key], query_value).first
      else
        resource_class.where(query, query_value).first
      end

#      if ActiveRecord::Base.connection.adapter_name.downcase.starts_with? 'mysql'
#        q = "BINARY " + q
#      end
    end

    def configuration
      GrapeTokenAuth.configuration
    end

    def set_resource_class
      @resource_class = configuration.scope_to_class(scope)
      fail(ScopeUndefinedError.new(scope)) unless resource_class
    end
  end
end

module DatabaseValidations
  module Validations
    extend ActiveSupport::Concern

    included do
      alias_method :validate, :valid?
    end

    attr_accessor :_database_validations_fallback

    def valid?(context = nil)
      self._database_validations_fallback = true
      super(context)
    end

    def create_or_update(*args, &block)
      self._database_validations_fallback = false
      ActiveRecord::Base.connection.transaction(requires_new: true) { super }
    rescue ActiveRecord::InvalidForeignKey, ActiveRecord::RecordNotUnique => e
      raise e unless Rescuer.handled?(self, e)

      raise ActiveRecord::RecordInvalid, self
    end

    private

    def perform_validations(options = {})
      options[:validate] == false || valid_without_database_validations?(options[:context])
    end
  end
end

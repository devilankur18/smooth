module Smooth
  module Presentable
    extend ActiveSupport::Concern

    included do
      unless ancestors.include?(Smooth::Queryable)
        send(:include,Smooth::Queryable)
      end

      column_names = self.column_names.map {|c| ":#{ c }" }.join(", ")

      code = "class ::#{ to_s }Presenter; def self.default; [#{ column_names }];end;end"

      eval(code)
    end

    def presenter
      (self.class.to_s + "Presenter").constantize
    end

    def present_as(format=:default)
      record = self
      config = presenter.send(format)

      presented = config.inject({}) do |memo,item|
        memo[item] = record.send(item)
        memo
      end
    end

    class PresentableChain
      attr_accessor :scope, :format, :recipient

      def initialize(scope)
        @scope      = scope
        @format     = :default
        @recipient  = :default
      end

      def as(format=:default)
        @format = format
        self
      end

      def to(recipient=:default)
        @recipient = recipient
        self
      end

      def results
        @results ||= scope.map do |record|
          record.present_as(format)
        end
      end

      def method_missing meth, *args, &block
        results.send(meth, *args, &block)
      end

    end

    module Controller
      extend ActiveSupport::Concern

      included do
        respond_to :json
        class_attribute :resource
      end

      def index
        resource_model.present(params).as(presenter_format).to(current_user_role)
      end

      protected

        def current_user_role
          current_user && current_user.try(:role)
        end

        def presenter_format
          params[:presenter] || params[:presenter_format]
        end

        def resource_model
          "#{ self.class.send(:resource) }".constantize
        end
    end

    module ClassMethods
      def present params={}
        scope = query(params)
        PresentableChain.new(scope)
      end
    end
  end
end

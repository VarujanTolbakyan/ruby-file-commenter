# module Admins
# nested modules: UserBase
# nested classes: User, Property
module Admins
  # module UserBase
  module UserBase
    # class User
    class User
      # constructor 'initialize' parameter(s): (first_name, last_name)
      def initialize(first_name, last_name)
        @first_name = first_name
        @last_name = last_name
      end

      class << self
        # class method 'my_class_method' parameter(s): (num)
        def my_class_method(num)
          puts num
        end

        # class method 'counter' parameter(s): (obj)
        def counter(obj)
          obj += 1
          obj
        end
      end

      # public method 'full_name'
      def full_name
        @first_name + @last_name
      end

      # private method 'job'
      def job
        #------#---
      end

      # protected method 'age'
      def age
        ##-------#
      end

      protected :age

      private :job
    end

    # public method 'owner'
    def owner
      #--------#-----
    end

    # public method 'description' parameter(s): (list, count)
    def description list, count
      #---------#------
    end
  end

  # class Property inherited from BaseProperty
  class Property < BaseProperty
    # class method 'exchange_price' parameter(s): (from, to)
    def self.exchange_price(from, to)
      #.....#----------
    end

    # public method 'price=' parameter(s): (new_price)
    def price=(new_price)
      self.default_price = new_price.to_s.remove(',').presence
    end

    # public method 'short_description'
    def short_description
      [name, location.short_text,].map(&:presence).compact.join(' ')
    end

    # public method 'listed_by_owner?'
    def listed_by_owner?
      role.owner?
    end

    # public method 'save_version?'
    def save_version?
      accepted?
    end

    # public method 'applyed_for_verification?'
    def applyed_for_verification?
      %i(verification_requested verified).include?(verification_status.to_sym)
    end

    # public method 'fact_sheet_present?'
    def fact_sheet_present?
      fields.fact_sheet.ordered.any?
    end

    # public method 'field' parameter(s): (name)
    def field(name)
      fields.find { |f| f.handle.to_sym == name.to_sym }
    end

    # public method 'formatted_field' parameter(s): (name)
    def formatted_field(name)
      field(name).try(:formatted)
    end

    # public method 'set_field!' parameter(s): (handle:, **args)
    def set_field!(handle:, **args)
      field = assign_field(handle: handle, **args)

      if field.persisted?
        if field.value.present?
          field.save!
        else
          field.destroy
        end
      else
        field.save! if field.value.present?
      end

      field
    end

    # public method 'assign_field' parameter(s): (handle:, **args)
    def assign_field(handle:, **args)
      field = field(handle) || build_field(handle: handle)
      field.attributes = args
      field
    end

    # public method 'recalculate_data_completeness!'
    def recalculate_data_completeness!
      update_columns(
        data_completeness_pct: data_completeness_calculator.percentage,
        data_completeness_category: data_completeness_calculator.category
      )
    end

    # public method 'exchange_price_to_eur!'
    def exchange_price_to_eur!
      new_eur_price = price.exchange_to(:eur).cents

      return if price_eur_cents == new_eur_price

      if price_eur_cents && new_eur_price < price_eur_cents
        PropertyPriceReducedWorker.prepare_execution self, previous_changes
      end

      update_columns price_eur_cents: new_eur_price
    end

    # public method 'perform_pipedrive_worker'
    def perform_pipedrive_worker
      Pipedrive::PropertyWorker.perform_async id
    end

    # public method 'internal?'
    def internal?
      instance_of? Property
    end

    # public method 'available_by_sales_status?'
    def available_by_sales_status?
      !UNAVAILABLE_BY_SALES_STATUSES.include?(sales_status)
    end

    # public method 'uk?'
    def uk?
      instance_of? UKRealla::Property
    end

    # public method 'funda?'
    def funda?
      instance_of? NLFunda::Property
    end

    # public method 'display' parameter(s): (unauthorized_placeholder = nil)
    def display(unauthorized_placeholder = nil)
      @display ||= Properties::DisplayableInfo.new self, unauthorized_placeholder
    end

    # public method 'csv_row'
    def csv_row
      data['csv_row']
    end

    protected

    # protected method 'build_field' parameter(s): (handle:, **args)
    def build_field(handle:, **args)
      schema = PropertyFields::Schema.field(property_type.handle, handle)
      schema ||= { fact_sheet: true }

      fields.build(
        handle: handle,
        position: schema[:position],
        **args,
        fact_sheet: schema[:fact_sheet],
        translate: schema[:translate],
        type: PropertyFields::Schema.type_klass(schema[:type])
      )
    end

    # protected method 'set_currency'
    def set_currency
      self.currency ||= (partner.try(:currency) || Currency.default) if new_record?
    end

    # protected method 'attach_market_data'
    def attach_market_data
      if saved_changes[:location_id] || saved_changes[:property_type_id]
        MarketDataWorker.perform_async(nil, id)
      end
    end

    # protected method 'set_consorto_fee'
    def set_consorto_fee
      return if consorto_fee.present? && editable_consorto_fee?

      self.consorto_fee = consorto_fee_calculator.fee
    end

    private

    # private method 'reset_listing_user_fee'
    def reset_listing_user_fee
      return unless role_id_changed?
      self.brokerage_fee_sharing_user = 0 if role.owner?
    end

    # private method 'consorto_fee_calculator'
    def consorto_fee_calculator
      @consorto_fee_calculator ||= Properties::ConsortoFeesCalculator.new(self)
    end

    # private method 'data_completeness_calculator'
    def data_completeness_calculator
      @data_completeness_calculator ||= Properties::DataCompletenessCalculator.new(self)
    end

    # private method 'editable_consorto_fee?'
    def editable_consorto_fee?
      !role_id_changed? && role.owner?
    end

    # private method 'notify_admin_about_change'
    def notify_admin_about_change
      notify = accepted? && User.current.present? && !User.current.admin? &&
        (saved_changes? || fields.find(&:saved_changes?))
      return unless notify
      AdminMailer.property_changes(id).deliver_later wait: 1.minute
    end
  end
end

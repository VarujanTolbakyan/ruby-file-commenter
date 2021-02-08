module Admins
  module UserBase
    class User
      def initialize(first_name, last_name)
        @first_name = first_name
        @last_name = last_name
      end

      class << self
        def my_class_method(num)
          puts num
        end

        def counter(obj)
          obj += 1
          obj
        end
      end

      def full_name
        @first_name + @last_name
      end

      def job
        #------#---
      end

      def age
        ##-------#
      end

      protected :age

      private :job
    end

    def owner
      #--------#-----
    end

    def description list, count
      #---------#------
    end
  end

  class Property < BaseProperty
    def self.exchange_price(from, to)
      #.....#----------
    end

    def price=(new_price)
      self.default_price = new_price.to_s.remove(',').presence
    end

    def short_description
      [name, location.short_text,].map(&:presence).compact.join(' ')
    end

    def listed_by_owner?
      role.owner?
    end

    def save_version?
      accepted?
    end

    def applyed_for_verification?
      %i(verification_requested verified).include?(verification_status.to_sym)
    end

    def fact_sheet_present?
      fields.fact_sheet.ordered.any?
    end

    def field(name)
      fields.find { |f| f.handle.to_sym == name.to_sym }
    end

    def formatted_field(name)
      field(name).try(:formatted)
    end

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

    def assign_field(handle:, **args)
      field = field(handle) || build_field(handle: handle)
      field.attributes = args
      field
    end

    def recalculate_data_completeness!
      update_columns(
        data_completeness_pct: data_completeness_calculator.percentage,
        data_completeness_category: data_completeness_calculator.category
      )
    end

    def exchange_price_to_eur!
      new_eur_price = price.exchange_to(:eur).cents

      return if price_eur_cents == new_eur_price

      if price_eur_cents && new_eur_price < price_eur_cents
        PropertyPriceReducedWorker.prepare_execution self, previous_changes
      end

      update_columns price_eur_cents: new_eur_price
    end

    def perform_pipedrive_worker
      Pipedrive::PropertyWorker.perform_async id
    end

    def internal?
      instance_of? Property
    end

    def available_by_sales_status?
      !UNAVAILABLE_BY_SALES_STATUSES.include?(sales_status)
    end

    def uk?
      instance_of? UKRealla::Property
    end

    def funda?
      instance_of? NLFunda::Property
    end

    def display(unauthorized_placeholder = nil)
      @display ||= Properties::DisplayableInfo.new self, unauthorized_placeholder
    end

    def csv_row
      data['csv_row']
    end

    protected

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

    def set_currency
      self.currency ||= (partner.try(:currency) || Currency.default) if new_record?
    end

    def attach_market_data
      if saved_changes[:location_id] || saved_changes[:property_type_id]
        MarketDataWorker.perform_async(nil, id)
      end
    end

    def set_consorto_fee
      return if consorto_fee.present? && editable_consorto_fee?

      self.consorto_fee = consorto_fee_calculator.fee
    end

    private

    def reset_listing_user_fee
      return unless role_id_changed?
      self.brokerage_fee_sharing_user = 0 if role.owner?
    end

    def consorto_fee_calculator
      @consorto_fee_calculator ||= Properties::ConsortoFeesCalculator.new(self)
    end

    def data_completeness_calculator
      @data_completeness_calculator ||= Properties::DataCompletenessCalculator.new(self)
    end

    def editable_consorto_fee?
      !role_id_changed? && role.owner?
    end

    def notify_admin_about_change
      notify = accepted? && User.current.present? && !User.current.admin? &&
        (saved_changes? || fields.find(&:saved_changes?))
      return unless notify
      AdminMailer.property_changes(id).deliver_later wait: 1.minute
    end
  end
end

# frozen_string_literal: true

module Maintenance
  class ParamsTask < MaintenanceTasks::Task
    attribute :post_ids, :string

    validates :post_ids,
      presence: true,
      format: { with: /\A(\s?\d+(,\s?\d+\s?)*)\z/, allow_blank: true }

    attribute :content, :string, default: "default content"
    attribute :integer_attr, :integer, default: 111_222_333
    attribute :big_integer_attr, :big_integer, default: 111_222_333
    attribute :float_attr, :float, default: 12.34
    attribute :decimal_attr, :decimal, default: 12.34
    attribute :datetime_attr, :datetime
    attribute :date_attr, :date
    attribute :time_attr, :time
    attribute :boolean_attr, :boolean

    # Dropdown options with supported scenarios
    attribute :integer_dropdown_attr, :integer
    attribute :boolean_dropdown_attr, :boolean

    validates_inclusion_of :integer_dropdown_attr, in: [100, 200, 300], allow_nil: true
    validates_inclusion_of :boolean_dropdown_attr, within: [true, false], allow_nil: true

    # Dropdown options with unsupported scenarios
    attribute :text_integer_attr_proc_no_arg, :integer
    attribute :text_integer_attr_proc_arg, :integer
    attribute :text_integer_attr_undefined_symbol, :integer
    attribute :text_integer_attr_unbounded_range, :integer
    attribute :text_integer_attr_bounded_range, :integer
    attribute :text_integer_attr_enumerable, :integer

    validates_inclusion_of :text_integer_attr_proc_no_arg, in: proc { [100, 200, 300] }, allow_nil: true
    validates_inclusion_of :text_integer_attr_proc_arg, in: proc { |_task| [100, 200, 300] }, allow_nil: true
    validates_inclusion_of :text_integer_attr_undefined_symbol, in: :undefined_symbol, allow_nil: true
    validates_inclusion_of :text_integer_attr_unbounded_range, in: (100..), allow_nil: true
    validates_inclusion_of :text_integer_attr_bounded_range, in: (100..120), allow_nil: true
    validates_inclusion_of :text_integer_attr_enumerable, in: (100..120).step(5), allow_nil: true

    class << self
      attr_accessor :fast_task
    end

    def collection
      Post.where(id: post_ids_array)
    end

    def process(post)
      sleep(1) unless self.class.fast_task

      post.update!(content: "New content added on #{Time.now.utc}:\ndatetime_attr: #{datetime_attr.inspect}")
    end

    private

    def post_ids_array
      post_ids.split(",")
    end
  end
end

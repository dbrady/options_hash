require "options_hash/version"

class OptionsHash

  class Option
    def initialize required, default=nil
      @required, @default = !!required, default
    end
    def required?; @required; end
    attr_reader :default
    def has_default?
      !!default
    end
    def has_default_proc?
      default.is_a? Proc
    end
    def inspect
      %(#{required? ? 'required' : 'optional'} #{default ? 'with' : 'without'} default)
    end
    alias_method :to_s, :inspect
  end

  def self.inherited(subclass)
    subclass.send :extend,  ClassMethods
    subclass.send :include, InstanceMethods
    subclass
  end

  class << self
    alias_method :_new, :new
    undef_method :new
    private :_new
    def parse options, &block
      block_given? or raise ArgumentError, 'block required', caller(2)
      Class.new(self, &block).parse(options)
    rescue ArgumentError => error
      raise ArgumentError, error.message, caller(2)
    end
  end

  module ClassMethods

    def parse options
      _new options
    rescue ArgumentError => error
      raise ArgumentError, error.message, caller(2)
    end

    def options
      @options ||= {}
      (superclass.respond_to?(:options) ? superclass.options : {}).merge @options
    end

    def option? key
      keys.include? key
    end

    def [] key
      option? key or raise KeyError, "#{key} is not an option", caller(1)
      options[key]
    end

    def keys
      options.keys.to_set
    end

    def required_keys
      options.select{|key, option| option.required? }.keys.to_set
    end

    def optional_keys
      options.reject{|key, option| option.required? }.keys.to_set
    end

    def required *options, &block
      default = extract_default options, &block
      set_options Option.new(true, default), *options
    end

    def optional *options, &block
      default = extract_default options, &block
      set_options Option.new(false, default), *options
    end

    def define_attr_readers object, instance_variable_name=:@options
      self.freeze
      instance_variable_name = "@#{instance_variable_name.to_s.sub(/@/,'')}"
      keys.each do |key|
        object.send(:define_method, "#{key}" ) do
          instance_variable_get(instance_variable_name)[key]
        end
      end
    end

    alias_method :_inspect, :inspect
    private :_inspect

    def class_name
      name || "OptionsHash:#{_inspect[/^#<Class:(\w+)/,1]}"
    end

    def inspect
      inspect = super
      required_keys = self.required_keys.to_a.sort
      optional_keys = self.optional_keys.to_a.sort
      "#{class_name}(required: #{required_keys.inspect}, optional: #{optional_keys.inspect})"
    end
    alias_method :to_s, :inspect

    private

    def extract_default options, &block
      return block if block_given?
      (options.last.is_a?(Hash) ? options.pop : {})[:default]
    end

    def set_options definition, *options
      @options ||= {}
      options.each do |key|
        key = key.to_sym
        @options[key] = definition.dup
        define_method("#{key}" ){ fetch key }
        define_method("#{key}?"){ given? key }
      end
    end

  end

  module InstanceMethods
    def initialize given_options
      @keys          = self.class.keys.freeze
      @options       = self.class.options.freeze
      @given_options = (given_options || {}).freeze

      unknown_options = @given_options.keys - keys.to_a
      unknown_options.empty? or raise ArgumentError, "unknown options: #{unknown_options.sort.map(&:inspect).join(', ')}"

      missing_required_options = required_keys.to_a - @given_options.keys
      missing_required_options.empty? or raise ArgumentError, "required options: #{missing_required_options.sort.map(&:inspect).join(', ')}"


      @values        = {}
      keys.to_a.sort.each{|key| send(key) }
    end
    attr_reader :keys, :options, :given_options

    def required_keys
      @options.select do |key, option|
        option.required?
      end.keys.to_set
    end

    def given? key
      @given_options.key? key
    end

    def fetch key
      key = key.to_sym
      keys.include?(key) or raise KeyError, "#{key} is not an option", caller(1)
      return @values[key] if @values.key? key

      option = @options[key]
      default_proc = option.default if option.default && option.default.is_a?(Proc)

      if option.required?
        value = @given_options[key]
        value = instance_exec(value, &default_proc) if option.required? && default_proc
        return @values[key] = value
      end

      return @values[key] = @given_options[key] if @given_options.key? key
      return @values[key] = default_proc ? instance_exec(&default_proc) : option.default
    end
    alias_method :[], :fetch

    def to_hash
      keys.each_with_object Hash.new do |key, hash|
        hash[key] = send(key)
      end
    end


    def inspect
      %(#<#{self.class.class_name} #{to_hash.inspect}>)
    end
    alias_method :to_s, :inspect
  end

end


# class Foo

#   def whatever options={}
#     OptionsHash.parse(options) do
#       required :name
#       optional :size, default: 42
#     end
#   end

# end




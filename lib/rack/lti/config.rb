require 'ims/lti'

module Rack::LTI
  class Config < Hash
    DEFAULT = {
      app_path:        '/',
      config_path:     '/lti/config.xml',
      description:     'An LTI Application.',
      launch_path:     '/lti/launch',
      nonce_validator: true,
      success:         ->(params, session) { session['launch_params'] = params if session },
      time_limit:      60*60,
      title:           'LTI App'
    }

    def initialize(options = {})
      DEFAULT.merge(options).each { |k, v| self[k] = v }
      instance_eval { yield(self) } if block_given?
    end

    [:consumer_key, :consumer_secret, :nonce_validator].each do |method|
      define_method(method) do |*args|
        if self[method].respond_to?(:call)
          self[method].call(*args)
        else
          self[method]
        end
      end
    end

    def public?
      self[:consumer_key].nil? && self[:consumer_secret].nil?
    end

    def to_xml(options = {})
      # Stringify keys for IMS::LTI
      config = self.merge(options).inject({}) do |h, v|
        h[v[0].to_s] = v[1]
        h
      end

      IMS::LTI::ToolConfig.new(config).to_xml(indent: 2)
    end

    def method_missing(method, *args, &block)
      if method.match(/=$/)
        self[method.to_s[0..-2].to_sym] = args.first
      elsif self.has_key?(method)
        self[method]
      else
        super
      end
    end
  end
end

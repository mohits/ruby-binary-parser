class Proxy < BasicObject
  def initialize(target, proxy_methods)
    @target = target
    @proxy_methods = proxy_methods
  end

  def method_missing(message, *args, &block)
    if @proxy_methods.include?(message)
      @target.__send__(message, *args, &block)
    else
      @target.symbol_call(message, *args, &block)
    end
  end
end

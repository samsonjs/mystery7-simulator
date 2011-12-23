class Result
  attr_accessor :roll, :sets, :parity, :colour, :highlow, :abc, :fmu

  def initialize(options)
    @roll = options[:roll]
    @sets = options[:sets]
    @parity = options[:parity]
    @colour = options[:colour]
    @highlow = options[:highlow]
    @abc = options[:abc]
    @fmu = options[:fmu]
  end
end

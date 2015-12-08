class Plan
  PLANS = [:free, :premium]

  def self.options
    PLANS.map { |plan| [plan.to_s.capitalize, plan]}
  end
end

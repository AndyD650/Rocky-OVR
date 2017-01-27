class Reg2DomainConstraint
  DOMAINS=%w(localhost2 register2 staging2 dev2).freeze
  def matches?(request)
    DOMAINS.include? request.domain.split(".").first
  end
end
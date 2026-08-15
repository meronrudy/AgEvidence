class DeterminationPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  def show?
    same_organization?
  end
end

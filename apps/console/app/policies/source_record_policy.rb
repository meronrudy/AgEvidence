class SourceRecordPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  def show?
    same_organization?
  end

  def create?
    has_any_role?(:org_admin, :operator, :reviewer)
  end
end

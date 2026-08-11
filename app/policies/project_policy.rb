class ProjectPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  def show?
    same_organization?
  end

  alias evidence? show?
  alias assessment? show?
  alias review? show?
  alias artifact? show?
  alias activity? show?

  def review_decision?
    has_any_role?(:org_admin, :reviewer, :approver)
  end

  def issue_artifact?
    has_any_role?(:org_admin, :operator, :approver)
  end
end

class ProjectPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
  end

  def show?
    same_organization?
  end

  alias evidence? show?
  alias source_records? show?
  alias runs? show?
  alias gaps? show?
  alias reliance? show?
  alias assessment? show?
  alias review? show?
  alias artifact? show?
  alias activity? show?

  def create_source_record?
    has_any_role?(:org_admin, :operator, :reviewer)
  end

  def create_reliance_event?
    has_any_role?(:org_admin, :operator, :approver)
  end

  def review_decision?
    has_any_role?(:org_admin, :reviewer, :approver)
  end

  def issue_artifact?
    has_any_role?(:org_admin, :operator, :approver)
  end
end

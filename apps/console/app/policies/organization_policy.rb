# app/policies/organization_policy.rb
class OrganizationPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user
      return scope.all if user.platform_admin?

      scope.where(id: user.organization_memberships.active.select(:organization_id))
    end
  end

  def show?
    same_organization?
  end

  alias organization? show?

  def update?
    has_any_role?(:org_admin)
  end

  def destroy?
    has_any_role?(:org_admin)
  end
end

# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      return scope.none unless user
      return scope.all if user.platform_admin?

      scope.joins(:organization_memberships)
           .where(organization_memberships: { organization_id: user.organization_memberships.active.select(:organization_id) })
           .distinct
    end
  end

  def index?
    user.present?
  end

  def show?
    record == user || shared_organization?
  end

  def create?
    user.present?
  end

  def update?
    record == user
  end

  def destroy?
    record == user
  end

  private

  def shared_organization?
    (user.organization_ids & record.organization_ids).any?
  end
end

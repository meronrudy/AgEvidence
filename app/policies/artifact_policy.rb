# app/policies/artifact_policy.rb
class ArtifactPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user
      return scope.all if user.platform_admin?

      org_artifacts = scope.joins(:project).where(projects: { organization_id: user.organization_memberships.active.select(:organization_id) }).select(:id)
      granted_artifacts = user.resource_grants.active.where(grantable_type: "Artifact").select(:grantable_id)
      scope.where(id: org_artifacts).or(scope.where(id: granted_artifacts))
    end
  end

  def show?
    same_organization? || resource_granted?
  end

  alias artifact? show?

  def create?
    has_any_role?(:org_admin, :operator, :reviewer, :approver)
  end

  def update?
    has_any_role?(:org_admin, :operator)
  end

  def destroy?
    has_any_role?(:org_admin)
  end

  def download?
    show?
  end

  def issue?
    has_any_role?(:org_admin, :operator, :approver)
  end

  private

  def resource_granted?
    return false unless user

    user.resource_grants.active.for_resource(record).exists?
  end
end

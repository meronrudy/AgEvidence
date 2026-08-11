class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    same_organization?
  end

  def create?
    has_any_role?(:org_admin, :operator)
  end

  def update?
    has_any_role?(:org_admin, :operator)
  end

  def destroy?
    has_any_role?(:org_admin)
  end

  private

  def organization
    return record if record.is_a?(Organization)
    return record.organization if record.respond_to?(:organization)
    return record.project.organization if record.respond_to?(:project) && record.project
  end

  def same_organization?
    return false unless user && organization

    user.platform_admin? || user.can_access_organization?(organization)
  end

  def has_any_role?(*roles)
    return false unless user && organization
    return true if user.platform_admin?

    roles.any? { |role| user.has_role?(organization, role) }
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      return scope.none unless user
      return scope.all if user.platform_admin?

      if scope.column_names.include?("organization_id")
        scope.where(organization_id: user.organization_memberships.active.select(:organization_id))
      elsif scope.reflect_on_association(:project)
        scope.joins(:project).where(projects: { organization_id: user.organization_memberships.active.select(:organization_id) })
      else
        scope.all
      end
    end
  end
end

class ApiPrincipal
  attr_reader :api_key

  def initialize(api_key)
    @api_key = api_key
  end

  def platform_admin?
    false
  end

  def can_access_organization?(organization)
    api_key&.organization_id == organization&.id
  end

  def has_role?(organization, role_name)
    can_access_organization?(organization) && %i[org_admin operator reviewer approver].include?(role_name.to_sym)
  end

  def organization_memberships
    OrganizationMembership.where(organization_id: api_key&.organization_id)
  end

  def resource_grants
    ResourceGrant.none
  end
end

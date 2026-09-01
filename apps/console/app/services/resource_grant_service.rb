class ResourceGrantService
  def self.grant!(user:, resource:, granted_by:, access_level: "read", expires_in: 30.days, recipient_name: nil, recipient_email: nil, metadata: {})
    grant = ResourceGrant.create!(
      user: user,
      grantable: resource,
      granted_by_user: granted_by,
      access_level: access_level,
      expires_at: expires_in.from_now,
      recipient_name: recipient_name,
      recipient_email: recipient_email
    )

    AuditEvent.log!(
      action: "resource_grant_created",
      actor: granted_by,
      organization: resource.organization,
      auditable: resource,
      metadata: metadata.merge(grantee_user_id: user.id, access_level: access_level, recipient_email: recipient_email)
    )

    grant
  end

  def self.revoke!(grant:, revoked_by:, metadata: {})
    grant.revoke!(revoked_by: revoked_by)
    AuditEvent.log!(
      action: "resource_grant_revoked",
      actor: revoked_by,
      organization: grant.grantable.organization,
      auditable: grant.grantable,
      metadata: metadata.merge(grantee_user_id: grant.user_id)
    )
    grant
  end

  def self.record_download!(grant:, actor:, metadata: {})
    grant.record_download!
    AuditEvent.log!(
      action: "resource_grant_downloaded",
      actor: actor,
      organization: grant.grantable.organization,
      auditable: grant.grantable,
      metadata: metadata.merge(grant_id: grant.id, grantee_user_id: grant.user_id)
    )
  end

  def self.access?(user:, resource:, level: "read")
    return true if user.can_access_organization?(resource.organization)

    grant = user.resource_grants.active.for_resource(resource).first
    return false unless grant

    levels = %w[read write admin]
    levels.index(grant.access_level).to_i >= levels.index(level).to_i
  end
end

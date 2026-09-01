class InvitationService
  def self.create!(organization:, email:, role_name:, invited_by:, expires_in: 7.days, metadata: {})
    role = organization.role(role_name)
    invitation = Invitation.create!(
      organization: organization,
      email: email.to_s.downcase.strip,
      role: role,
      invited_by_user: invited_by,
      expires_at: expires_in.from_now,
      status: "pending"
    )

    AuditEvent.log!(
      action: "invitation_created",
      actor: invited_by,
      organization: organization,
      auditable: invitation,
      metadata: metadata
    )

    invitation
  end
end

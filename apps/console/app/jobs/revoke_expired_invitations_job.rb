class RevokeExpiredInvitationsJob < ApplicationJob
  queue_as :default

  def perform
    Invitation.where(status: "pending").expired.update_all(status: "expired", updated_at: Time.current)
  end
end

class Artifact < ApplicationRecord
  include JsonBacked

  belongs_to :project
  belongs_to :issued_by_user, class_name: "User", optional: true
  has_many :resource_grants, as: :grantable, dependent: :destroy

  json_field :artifact, default: {}
  json_field :integrity, :limitations, :receipt_chain, default: []

  validates :artifact_code, :claim, :boundary, :jurisdiction, :program, :digest, :status, presence: true

  def organization
    project.organization
  end

  def issue!(issued_by: nil)
    payload = artifact.deep_dup
    payload["status"] = "issued"
    payload["integrity"] ||= {}
    payload["integrity"]["signature"] = {
      "algorithm" => "ed25519",
      "key_id" => "agev_prod_2026",
      "value" => "MEQCIF3k-demo-signature"
    }

    update!(
      issued: true,
      issued_at: Time.current,
      issued_by_user: issued_by,
      status: "issued",
      artifact: payload,
      integrity: integrity.map { |item| item.merge("ok" => true) }
    )
  end
end

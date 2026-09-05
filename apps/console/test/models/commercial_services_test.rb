require "test_helper"

class CommercialServicesTest < ActiveSupport::TestCase
  setup do
    seed_demo!
    @project = Project.find_by!(slug: "dit-production")
    @actor = User.find_by!(email: "emma@agevidence.example")
  end

  test "source record intake writes record and audit atomically" do
    attrs = {
      source_system: "uDOSE SDK",
      document_id: "DOC-ATOMIC-001",
      evidence_type: "source_record",
      evidence_class: "controlled_source",
      controlled_uri: "https://sources.example/DOC-ATOMIC-001",
      commitment: "sha256:#{SecureRandom.hex(16)}",
      disclosure_status: "available",
      status: "received"
    }

    assert_difference -> { SourceRecord.count }, 1 do
      assert_difference -> { AuditEvent.where(action: "source_record_intaked").count }, 1 do
        SourceRecordIntakeService.create!(project: @project, actor: @actor, attributes: attrs, metadata: { request_id: "req-test" })
      end
    end
  end

  test "source record normalizes to separate evidence record with provenance digest" do
    source = SourceRecord.find_by!(record_code: "SR-DIT-SDK")

    evidence = EvidenceNormalizationService.create_from_source!(
      source_record: source,
      actor: @actor,
      projection: "agevidence.seed_projection.v0",
      schema_name: "seed_projection.v0",
      payload: { "value" => "42" },
      metadata: { request_id: "normalize-test" }
    )

    assert_equal source, evidence.source_record
    assert_match(/\Aapp:sha256:/, evidence.digest)
    assert_equal "EV-", evidence.record_code.first(3)
  end

  test "unchanged input records separate model runs with matching input commitment" do
    attrs = {
      adapter_name: "AUS-LIVESTOCK-ME",
      adapter_version: "v0.9",
      input_commitment: "sha256:unchangedinput0001",
      status: "completed",
      output: { "ok" => true }
    }

    first = ModelRunRecordingService.create!(project: @project, actor: @actor, attributes: attrs)
    second = ModelRunRecordingService.create!(project: @project, actor: @actor, attributes: attrs)

    refute_equal first.run_code, second.run_code
    assert_equal first.input_commitment, second.input_commitment
  end

  test "failed model run does not create accepted candidates" do
    run = ModelRunRecordingService.create!(
      project: @project,
      actor: @actor,
      attributes: {
        adapter_name: "AUS-LIVESTOCK-ME",
        adapter_version: "v0.9",
        input_commitment: "sha256:failedinput0001",
        status: "failed",
        failure_reason: "adapter timeout"
      },
      candidates: [{ candidate_type: "claim", claim: "Should not persist", status: "accepted" }]
    )

    assert_equal "adapter timeout", run.failure_reason
    assert_empty run.evidence_candidates
  end

  test "candidate disposition is attributable and preserves claim" do
    candidate = EvidenceCandidate.find_by!(candidate_code: "EC-AU-00041-1")
    original_claim = candidate.claim

    disposition = EvidenceCandidateDispositionService.record!(
      candidate: candidate,
      status: "rejected",
      reason: "Insufficient basis",
      actor: @actor,
      metadata: { request_id: "candidate-test" }
    )

    assert_equal @actor, disposition.actor
    assert_equal "rejected", candidate.reload.status
    assert_equal original_claim, candidate.claim
  end

  test "gap detection uses deterministic code without duplicating open gap" do
    args = {
      project: @project,
      requirement_code: "AE-METH-999",
      severity: "high",
      title: "Missing source custody",
      explanation: "The source commitment is missing.",
      expected: ["source commitment"],
      observed: ["none"],
      blocking: true,
      actor: @actor
    }

    assert_difference -> { Gap.count }, 1 do
      GapDetectionService.record!(**args)
    end

    assert_no_difference -> { Gap.count } do
      GapDetectionService.record!(**args)
    end
  end

  test "artifact digest changes when material inputs change" do
    determination = Determination.find_by!(determination_code: "DET-AU-000184")
    artifact = ArtifactAssemblyService.assemble!(determination: determination, actor: @actor)
    original_digest = artifact.digest
    determination.result = determination.result.merge("limitations" => [{ "code" => "LIM-X", "statement" => "Changed", "basis" => "test" }])
    determination.save!

    changed = ArtifactAssemblyService.assemble!(determination: determination, actor: @actor)

    refute_equal original_digest, changed.digest
  end

  test "reliance event does not change artifact digest or json" do
    artifact = Artifact.find_by!(artifact_code: "AE-AU-000184")
    original_digest = artifact.digest
    original_json = artifact.artifact

    RelianceEventRecorder.record!(
      artifact: artifact,
      actor: @actor,
      attributes: {
        relying_party: "Recipient application",
        relying_party_role: "recipient",
        reliance_kind: "assurance",
        status: "recorded"
      }
    )

    artifact.reload
    assert_equal original_digest, artifact.digest
    assert_equal original_json, artifact.artifact
  end

  test "issued statement substance cannot be silently updated" do
    artifact = Artifact.find_by!(artifact_code: "AE-AU-000179")

    assert artifact.issued?
    assert_not artifact.update(claim: "Changed claim")
    assert_includes artifact.errors[:base].join, "issued artifact substance is immutable"
  end

  test "expired and revoked grants deny access" do
    artifact = Artifact.find_by!(artifact_code: "AE-AU-000184")
    recipient = User.create!(
      email: "recipient@example.com",
      first_name: "Recipient",
      last_name: "User",
      password: "correct-horse-battery-staple",
      confirmed_at: Time.current
    )
    grant = ResourceGrantService.grant!(user: recipient, resource: artifact, granted_by: @actor, expires_in: 1.day)

    assert ResourceGrantService.access?(user: recipient, resource: artifact)

    ResourceGrantService.revoke!(grant: grant, revoked_by: @actor)
    assert_not ResourceGrantService.access?(user: recipient, resource: artifact)

    expired_grant = ResourceGrantService.grant!(user: recipient, resource: artifact, granted_by: @actor, expires_in: -1.day)
    assert expired_grant.expired?
    assert_not ResourceGrantService.access?(user: recipient, resource: artifact)
  end
end

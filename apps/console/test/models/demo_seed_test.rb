require "test_helper"

class DemoSeedTest < ActiveSupport::TestCase
  test "seed creates canonical demo data and is idempotent" do
    seed_demo!

    counts = {
      organizations: Organization.count,
      users: User.count,
      roles: Role.count,
      organization_memberships: OrganizationMembership.count,
      invitations: Invitation.count,
      projects: Project.count,
      source_records: SourceRecord.count,
      evidence_records: EvidenceRecord.count,
      gaps: Gap.count,
      model_runs: ModelRun.count,
      evidence_candidates: EvidenceCandidate.count,
      evidence_cases: EvidenceCase.count,
      program_profiles: ProgramProfile.count,
      artifact_profiles: ArtifactProfile.count,
      artifacts: Artifact.count,
      verifier_results: VerifierResult.count,
      reliance_events: RelianceEvent.count,
      price_versions: PriceVersion.count,
      pricing_quotes: PricingQuote.count,
      artifact_orders: ArtifactOrder.count,
      commercial_outcomes: CommercialOutcome.count,
      commercial_events: CommercialEvent.count,
      domain_mappings: DomainMapping.count
    }

    seed_demo!

    assert_equal counts, {
      organizations: Organization.count,
      users: User.count,
      roles: Role.count,
      organization_memberships: OrganizationMembership.count,
      invitations: Invitation.count,
      projects: Project.count,
      source_records: SourceRecord.count,
      evidence_records: EvidenceRecord.count,
      gaps: Gap.count,
      model_runs: ModelRun.count,
      evidence_candidates: EvidenceCandidate.count,
      evidence_cases: EvidenceCase.count,
      program_profiles: ProgramProfile.count,
      artifact_profiles: ArtifactProfile.count,
      artifacts: Artifact.count,
      verifier_results: VerifierResult.count,
      reliance_events: RelianceEvent.count,
      price_versions: PriceVersion.count,
      pricing_quotes: PricingQuote.count,
      artifact_orders: ArtifactOrder.count,
      commercial_outcomes: CommercialOutcome.count,
      commercial_events: CommercialEvent.count,
      domain_mappings: DomainMapping.count
    }
    assert_equal 2, Organization.count
    assert_equal "AE-AU-000184", Artifact.find_by!(artifact_code: "AE-AU-000184").artifact_code
    assert_equal "dit-production", Project.find_by!(project_code: "PRJ-AU-00041").slug
    assert_equal "DET-AU-000184", Determination.find_by!(project_name: "DIT Production Evidence").determination_code
    assert_equal "EVAL-AU-METH-001", Evaluation.find_by!(project_name: "DIT Production Evidence").evaluation_code
    assert_equal "dit-production", Evaluation.find_by!(evaluation_code: "EVAL-AU-METH-001").project.slug
    assert_equal "AU_METHANE_INTERVENTION_V1", ProgramProfile.find_by!(slug: "au-methane-intervention-v1").code
    assert_equal 15, ProgramProfile.find_by!(code: "AU_METHANE_INTERVENTION_V1").requirements.count
    primitive_chain = %w[SRC-PL-443 SRC-C-18 EVT-99231 OP-22019 OBS-828 MR-334].map { |code| EvidenceRecord.find_by!(record_code: code).record_type }
    assert_equal %w[source_record source_record intervention_event operational_event observation model_run], primitive_chain
    fixture_chain = JSON.parse(Rails.root.join("test/fixtures/evidence/dit_production_chain.json").read).fetch("records").map { |record| record.fetch("id") }
    assert_equal %w[SRC-PL-443 SRC-C-18 EVT-99231 OP-22019 OBS-828 MR-334], fixture_chain
    assert_equal "SR-DIT-SDK", SourceRecord.find_by!(record_code: "SR-DIT-SDK").record_code
    assert_equal "SR-DIT-SDK", EvidenceRecord.find_by!(record_code: "EVT-99231").source_record.record_code
    assert_equal "GF-4412", EvidenceRecord.find_by!(record_code: "OBS-828").payload.fetch("instrument")
    user = User.find_by!(email: "emma@agevidence.example")
    assert user.can_access_organization?(Organization.find_by!(name: "DIT AgTech"))
    assert user.can_access_organization?(Organization.find_by!(name: "Earthodic Demo"))
    assert user.valid_password?("demo")
    assert_equal user, User.find_for_database_authentication(email: "demo")

    earthodic = Organization.find_by!(name: "Earthodic Demo")
    assert_equal "earthodic", earthodic.portfolio_product_pack
    assert_equal "1.0.0", earthodic.portfolio_product_pack_version
    assert_equal "qualification.earthodic.com", earthodic.brand_domain
    assert_equal 7, earthodic.price_versions.count
    assert_equal "QA-EARTH-APP-001", Project.find_by!(project_code: "PRJ-EARTH-APP-001").artifact.artifact_code
    assert_equal "GAP-EARTH-APP-001", Gap.find_by!(gap_code: "GAP-EARTH-APP-001").gap_code

    price = earthodic.price_versions.find_by!(product_code: "application_qualification")
    assert_equal "1.2", price.product_version
    assert_equal "AUD", price.currency
    assert_equal "application", price.pricing_unit
    assert_equal 2_500_000, price.list_price_cents
    assert_equal 1_900_000, price.minimum_price_cents

    quote = earthodic.pricing_quotes.find_by!(quote_id: "QUOTE-EARTH-APP-001")
    assert_equal price, quote.price_version
    assert_equal 1_900_000, quote.offered_price_cents
    assert_equal "won", earthodic.commercial_outcomes.find_by!(product_code: "application_qualification").state
  end
end

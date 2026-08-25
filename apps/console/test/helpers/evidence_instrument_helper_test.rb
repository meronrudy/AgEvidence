require "test_helper"

class EvidenceInstrumentHelperTest < ActionView::TestCase
  test "semantic status tones are stable" do
    assert_equal "valid", ei_status_tone("valid")
    assert_equal "human_review", ei_status_tone("Human review")
    assert_equal "material_gap", ei_status_tone("schema_error")
    assert_equal "draft", ei_status_tone("draft")
    assert_equal "unverified", ei_status_tone("unknown")
  end
end

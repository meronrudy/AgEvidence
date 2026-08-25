class MarketingController < ApplicationController
  def index
    @flow = [
      "SDK", "Ingest", "Evaluate", "Find Gaps", "Review",
      "Determine", "Statement", "Issue", "Share", "Verify"
    ]
  end
end

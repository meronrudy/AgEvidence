class MarketingController < ApplicationController
  def index
    @flow = [
      "Connect", "Ingest Evidence", "Normalize", "Assess", "Find Gaps",
      "Human Review", "Assemble", "Issue", "Verify", "Rely"
    ]
  end
end

module EvidencePlane
  class OpenReview
    def self.call(project:, requirement_code:, title:, metadata: {})
      review = project.reviews.find_or_initialize_by(requirement_code: requirement_code, state: "open")
      review.review_code ||= "RV-#{SecureRandom.hex(3).upcase}"
      review.title = title
      review.save!
      review
    end
  end
end

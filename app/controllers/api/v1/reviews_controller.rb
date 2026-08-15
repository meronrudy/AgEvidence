module Api
  module V1
    class ReviewsController < BaseController
      def index
        require_scope!("reviews:read")
        reviews = policy_scope(Review).order(state: :asc, review_code: :asc)
        envelope(reviews.map { |review| serialize(review) })
      end

      private

      def serialize(review)
        {
          "id" => review.review_code,
          "requirement_code" => review.requirement_code,
          "title" => review.title,
          "state" => review.state
        }
      end
    end
  end
end

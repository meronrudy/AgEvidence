module Api
  module V1
    class ProgramProfilesController < BaseController
      def index
        require_scope!("program_profiles:read")
        envelope(ProgramProfile.order(:code, :profile_version).map { |profile| serialize(profile) })
      end

      def show
        require_scope!("program_profiles:read")
        profile = ProgramProfile.find_by!("code = ? OR slug = ?", params[:id], params[:id])
        envelope(serialize(profile).merge("requirements" => profile.requirements.order(:requirement_code).map { |req| serialize_requirement(req) }))
      end

      private

      def serialize(profile)
        {
          "id" => profile.code,
          "slug" => profile.slug,
          "name" => profile.name,
          "status" => profile.status,
          "profile_version" => profile.profile_version,
          "requirements_count" => profile.requirements_count,
          "machine_evaluable" => profile.machine_evaluable,
          "human_review" => profile.human_review
        }
      end

      def serialize_requirement(requirement)
        {
          "code" => requirement.requirement_code,
          "title" => requirement.title,
          "category" => requirement.category,
          "evaluation_mode" => requirement.evaluation_mode,
          "status" => requirement.status
        }
      end
    end
  end
end

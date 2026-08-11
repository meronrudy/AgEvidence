class HealthController < ApplicationController
  def show
    ActiveRecord::Base.connection.execute("SELECT 1")
    render json: { status: "ok", rails: Rails.version }
  rescue StandardError => error
    render json: { status: "error", error: error.class.name }, status: :service_unavailable
  end
end

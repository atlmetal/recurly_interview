class ApplicationController < ActionController::API
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing

  private

  def render_parameter_missing(exception)
    render json: {
      valid:   false,
      errors:  [ exception.message ],
      details: { param: exception.param }
    }, status: :bad_request
  end
end

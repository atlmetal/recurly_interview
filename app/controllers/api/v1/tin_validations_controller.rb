class Api::V1::TinValidationsController < ApplicationController
  wrap_parameters false

  def validate
    result = TinFormatValidatorService.call(tin_validation_params[:country].to_sym, tin_validation_params[:number])

    if result[:valid]
      render json: result, status: :ok
    else
      render json: result, status: :unprocessable_entity
    end
  end

  private

  def tin_validation_params
    params.require(:country)
    params.require(:number)
    params.permit(:country, :number)
  end
end

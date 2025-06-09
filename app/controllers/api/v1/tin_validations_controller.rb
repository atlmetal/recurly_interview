class Api::V1::TinValidationsController < ApplicationController
  def validate
    render json: TinFormatValidatorService.call(params[:country].to_sym, params[:tin]), status: :ok
  end
end

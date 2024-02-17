require 'securerandom'

class ApplicationsController < ApplicationController
  def create
    application = Application.new(application_params)
    application.token = SecureRandom.uuid
    application.chats_count = 0

    if application.save
      render json: application, status: :created
    else
      render json: application.errors, status: :bad_request
    end
  end

  def show
    application = Application.find_by(token: params[:token])
    if application
      render json:application
    else
      render json: "Application not Found", status: 404 unless application
    end
  end

  private
  def application_params
    params.require(:application).permit(:name)
  end
end

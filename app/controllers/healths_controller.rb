class HealthsController < ApplicationController
  def show
    render json: { alive: true }
  end
end

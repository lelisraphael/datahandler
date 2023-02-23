class HomeController < ApplicationController
  def index
    render json: { message: "Bem-vindo à minha API Rails!" }
  end
end

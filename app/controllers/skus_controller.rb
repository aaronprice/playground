class SkusController < ApplicationController

  def show
    render json: {
      sku: params[:id],
      currency: params[:currency] || "USD",
      price: sprintf("%.2f", (Digest::MD5.hexdigest(params[:id])[0..3].to_i(16) / 100.0)),
    }
  end
end
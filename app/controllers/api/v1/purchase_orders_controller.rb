class Api::V1::PurchaseOrdersController < ApplicationController

  def create
    service = PurchaseOrders::Receive.(purchase_order_params)

    if service.success?
      render json: service.value, status: :created
    else
      render json: { errors: service.errors }, status: :unprocessable_content
    end
  end

  private

  def purchase_order_params
    params.permit(
      :external_po_id,
      :requested_ship_date,
      :currency,
      customer: [
        :external_customer_ref,
        :name,
        :email,
        address: [
          :line_1,
          :line_2,
          :city,
          :state,
          :zip,
        ]
      ],
      lines: [[
        :sku,
        :quantity,
      ]]
    )&.to_h
  end
end
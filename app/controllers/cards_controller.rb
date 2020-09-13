class CardsController < ApplicationController
  before_action :set_card, only: [:show, :edit, :update]

  def index
    @cards = Card.seach_by_name_rarity_hp(params[:query]).paginate(page: params[:page], per_page: 40)
    respond_to do |format|
      format.js
      format.html
    end
  end

  def create_backup
    Card.create_backup
  end

  def delete_backup
    Card.delete_backup
  end
end
class Card
  include Mongoid::Document
  include Mongoid::Timestamps
  field :card_id, type: String
  field :name,    type: String
  field :national_pokedex_number, type: Integer
  field :image_url, type: String
  field :image_url_hi_res, type: String
  field :sub_type, type: String
  field :super_type, type: String
  field :ancient_trait, type: String
  field :hp, type: String
  field :number, type: String
  field :artist, type: String
  field :rarity, type: String
  field :series, type: String
  field :set, type: String
  field :set_code, type: String
  field :retreat_cost, type: Array, default: []
  field :converted_retreat_cost, type: Integer
  field :text, type: String
  field :ability, type: Hash, default: {}
  field :types, type: Array, default: []
  field :attacks, type: Array, default: []
  field :weaknesses, type: Array, default: []
  field :resistances, type: Array, default: []
  field :evolves_from, type: Array, default: []

  #
  #Indexes
  #
  index({name: 1}, background: true)
  index({hp: 1}, background: true)
  index({rarity: 1}, background: true)
  index({card_id: 1}, unique: true, background: true)
  class << self

    def seach_by_name_rarity_hp(query)
      if query.present?
        Card.or({name: query},{rarity: query},{hp: query})
      else
        all
      end
    end

    # This Method Call Pokemon API and Store into Database 
    # Todo
    # We Can schedule this job in perform later and with action cable
    # we can give realtime notification when this is completed.
    def create_backup
      page = 1
      while page >= 1
        cards = Pokemon::Card.where(page: page, pageSize: 100)
        page = cards.any? ? page += 1 : 0
        cards_attributes = map_cards(cards)
        store_backup(cards_attributes)
      end
    end

    # Delete Backup from database
    def delete_backup
      Card.delete_all
    end

    # Map each cards with an attributes
    def map_cards(raw_cards)
      raw_cards.each_with_object([]) do |card, cards|
        cards << get_card_attributes(card)
      end
    end

    def get_card_attributes(card)
      card = JSON.parse(card.to_json)
      return {} if !card.present?
      {
        card_id: card['id'],
        name: card['name'],
        national_pokedex_number: card['nationalPokedexNumber'],
        image_url: card['imageUrl'],
        image_url_hi_res: card['imageUrlHiRes'],
        sub_type: card['subtype'],
        super_type: card['supertype'],
        ability: card['ability'],
        ancient_trait: card['ancient_trait'],
        hp: card['hp'],
        number: card['number'],
        artist: card['artist'],
        rarity: card['rarity'],
        series: card['series'],
        set: card['set'],
        set_code: card['setCode'],
        retreat_cost: card['retreatCost'],
        converted_retreat_cost: card['convertedRetreatCost'],
        text: card['text'],
        types: card['types'],
        attacks: card['attacks'],
        weaknesses: card['weaknesses'],
        resistances: card['resistances'],
        evolves_from: card['evolves_from']
      }
    end

    #
    # Store backup into database
    # [] of cards required in args
    def store_backup(cards)
      return nil if !cards.is_a? Array or cards.blank?
      begin
        Card.collection.insert_many(cards, {ordered: false})
      rescue Mongo::Error::BulkWriteError => e
        # This Exception is OK because
        # we don't want to store dubplicate records.
        # Error Due to Duplicate Records
        Rails.logger.info "Backup was unable to save an error entry. Exception: #{e}"
      end
    end
  end
end
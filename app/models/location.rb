class Location
  attr_accessor :distance

  include Mongoid::Document

  field :name,          type: String
  field :latitude,      type: Float
  field :longitude,     type: Float
  field :materials,     type: Array
  field :residents,     type: Boolean
  field :business,      type: Boolean
  field :pick_up,       type: Boolean
  field :drop_off,      type: Boolean
  field :mail_in,       type: Boolean
  field :ecycle,        type: Boolean
  field :tibn,          type: Boolean
  field :location_type, type: String
  field :street,        type: String
  field :city,          type: String
  field :state,         type: String
  field :zipcode,       type: String
  field :phone,         type: String
  field :website,       type: String
  field :hours,         type: String
  field :fee,           type: Hash
  field :min_volume,    type: String
  field :max_volume,    type: String
  field :description,   type: Hash

  def self.search(location_params)
    location_params.inject(Location.all) do |result, (attribute, value)|
      if attribute == "materials"
        materials = value.split(",").map {|subcategory| subcategory.gsub("+", " ")}
        result.all_in(attribute => materials)
      else
        result.where(attribute => value)
      end
    end
  end
end
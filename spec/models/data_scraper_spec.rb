require 'spec_helper'

describe DataScraper do    
  let(:data_scraper){DataScraper.new(date_modified: "2013-04-14 10:17:59 -0700")}
  let(:location){Location.new}

  describe "set_materials" do
    it "adds material to materials array" do
      location.save
      DataScraper.set_materials("Bunnies", location)
      expect(location.materials).to eq(["Bunnies"])
    end
  end

  describe "set_state" do
    context "zipcode is in WA" do
      it "sets state to WA" do
        location.save
        DataScraper.set_state("98105", location)
        expect(location.state).to eq("WA")
      end
    end
  end

  describe "needs_updating?" do
    before do
      data_scraper.save
    end

    it "returns true if database has been updated" do
      expect(DataScraper.needs_updating?("2014-04-14 10:17:59 -0700")).to eq(true)
    end

    it "returns false if database has not been updated" do
      expect(DataScraper.needs_updating?("2013-04-14 10:17:59 -0700")).to eq(false)
    end
  end

  describe "create_location" do
    it "returns a Location instance" do
      expect(DataScraper.create_location(location_json).class).to eq(Location)
    end

    it "saves provider name" do
      expect(DataScraper.create_location(location_json).name).to eq("1 Green Planet")
    end

    it "saves description and restrictions together in misc_info" do
      expect(DataScraper.create_location(location_json).description).to eq('Anything with a cord on or anything with metal in it. Working or not or parts. Pickup service available upon arragement, typically for quantity of ten items or more.  Please inquire. Call to arrange drop off.')
    end

    it "saves pick_up" do
      expect(DataScraper.create_location(location_json).pick_up).to eq(true)
    end

    it "saves business" do
      expect(DataScraper.create_location(location_json).business).to eq(true)
    end

    it "handles nil service_description gracefully" do
      expect(DataScraper.create_location(location_json3).description).to eq('Anything with a cord on or anything with metal in it. Working or not or parts.')
    end

    it "handles nil restrictions gracefully" do
      expect(DataScraper.create_location(location_json4).description).to eq('Pickup service available upon arragement, typically for quantity of ten items or more.  Please inquire. Call to arrange drop off.')
    end
  end

  describe "update_or_create_location" do
    context "location doesn't exist" do
      it "creates location and adds materials" do
        expect(DataScraper.update_or_create_location(location_json).materials).to eq(['Air Conditioners, Heat Pumps'])
      end
    end

    context "location exists" do
      before do
        DataScraper.update_or_create_location(location_json)
      end

      it "doesn't create a location" do
        expect{DataScraper.update_or_create_location(location_json2)}.to change{Location.count}.by(0)
      end

      it "adds new materials" do
        expect(DataScraper.update_or_create_location(location_json2).materials).to eq(['Air Conditioners, Heat Pumps', 'Refrigerators'])
      end
    end
  end

  describe "update_date_modified" do
    it "updates the date" do
      data_scraper.save
      expect(DataScraper.last.date_modified).to eq("2013-04-14 10:17:59 -0700")
      DataScraper.update_date_modified("2014-04-14 10:17:59 -0700")
      expect(DataScraper.last.date_modified).to eq("2014-04-14 10:17:59 -0700")
    end
  end

  describe "update_or_leave_locations_alone" do

    context "database has been modified" do
      it "updates DataScraper's date modified" do
        prep_api_response

        expect(DataScraper.last.date_modified).to eq("2014-04-14 10:17:59 -0700")
      end

      it "makes API call and increments offset by 1000 until record count is <1000" do
        prep_api_response
      end
    end

    context "database has not been modified" do
      it "doesn't make an API call" do
        data_scraper.save

        expect(HTTParty).to_not receive(:get)
        DataScraper.update_or_leave_locations_alone("2013-04-14 10:17:59 -0700")
      end
    end     
  end

  describe "titleize" do
    it "doesn't capitalize special words" do
      expect(DataScraper.titleize("Beauty and the beast")).to eq("Beauty and the Beast")
    end
  end
end

def prep_api_response
  data_scraper.save

  response = double("response", :each => [])
  allow(response).to receive(:count).and_return(1000, 600)

  expect(HTTParty).to receive(:get).with("http://data.kingcounty.gov/resource/zqwi-c5q3.json?$limit=1000&$offset=0").and_return(response)
  expect(HTTParty).to receive(:get).with("http://data.kingcounty.gov/resource/zqwi-c5q3.json?$limit=1000&$offset=1000").and_return(response)

  DataScraper.update_or_leave_locations_alone("2014-04-14 10:17:59 -0700")
end

def location_json
  {"zip"=>"98057", "maximum_volume"=>"no maximum", "phone"=>{"phone_number"=>"(425) 996-3513"}, "providerid"=>"710", "restrictions"=>"Pickup service available upon arragement, typically for quantity of ten items or more.  Please inquire. Call to arrange drop off.", "location"=>"850 SW 7th St. WA 98057", "dropoff_allowed"=>"TRUE", "hours"=>"Mon - Fri:  9:30am - 6:30pm", "pickup_allowed"=>"TRUE", "city"=>"Renton", "material_handled"=>"Air Conditioners, Heat Pumps", "fee"=>"We provide free recycling to everyone !", "mapping_location"=>{"needs_recoding"=>false, "longitude"=>"-122.22809200647511", "latitude"=>"47.473790760173145", "human_address"=>"{\"address\":\"850 7th St\",\"city\":\"WA\",\"state\":\"\",\"zip\":\"98057\"}"}, "property_type"=>"Business, Residents", "geolocation"=>{"needs_recoding"=>false, "longitude"=>"-122.22763688128907", "latitude"=>"47.473764549319185", "human_address"=>"{\"address\":\"850 SW 7th St.\",\"city\":\"Renton\",\"state\":\"\",\"zip\":\"98057\"}"}, "minimum_volume"=>"no minimum", "mail_in_allowed"=>"TRUE", "service_description"=>"Anything with a cord on or anything with metal in it. Working or not or parts.", "provider_url"=>{"url"=>"http://1greenplanet.org"}, "provider_address"=>"850 SW 7th St.", "provider_name"=>"1 Green Planet"}
end

def location_json2
  {"zip"=>"98057", "maximum_volume"=>"no maximum", "phone"=>{"phone_number"=>"(425) 996-3513"}, "providerid"=>"710", "restrictions"=>"Pickup service available upon arragement, typically for quantity of ten items or more.  Please inquire. Call to arrange drop off.", "location"=>"850 SW 7th St. WA 98057", "dropoff_allowed"=>"TRUE", "hours"=>"Mon - Fri:  9:30am - 6:30pm", "pickup_allowed"=>"TRUE", "city"=>"Renton", "material_handled"=>"Refrigerators", "fee"=>"We provide free recycling to everyone !", "mapping_location"=>{"needs_recoding"=>false, "longitude"=>"-122.22809200647511", "latitude"=>"47.473790760173145", "human_address"=>"{\"address\":\"850 7th St\",\"city\":\"WA\",\"state\":\"\",\"zip\":\"98057\"}"}, "property_type"=>"Business, Residents", "geolocation"=>{"needs_recoding"=>false, "longitude"=>"-122.22763688128907", "latitude"=>"47.473764549319185", "human_address"=>"{\"address\":\"850 SW 7th St.\",\"city\":\"Renton\",\"state\":\"\",\"zip\":\"98057\"}"}, "minimum_volume"=>"no minimum", "mail_in_allowed"=>"TRUE", "service_description"=>"Anything with a cord on or anything with metal in it. Working or not or parts.", "provider_address"=>"850 SW 7th St.", "provider_name"=>"1 Green Planet"}
end

def location_json3
  {"zip"=>"98057", "maximum_volume"=>"no maximum", "phone"=>{"phone_number"=>"(425) 996-3513"}, "providerid"=>"710", "location"=>"850 SW 7th St. WA 98057", "dropoff_allowed"=>"TRUE", "hours"=>"Mon - Fri:  9:30am - 6:30pm", "pickup_allowed"=>"TRUE", "city"=>"Renton", "material_handled"=>"Refrigerators", "fee"=>"We provide free recycling to everyone !", "mapping_location"=>{"needs_recoding"=>false, "longitude"=>"-122.22809200647511", "latitude"=>"47.473790760173145", "human_address"=>"{\"address\":\"850 7th St\",\"city\":\"WA\",\"state\":\"\",\"zip\":\"98057\"}"}, "property_type"=>"Business, Residents", "geolocation"=>{"needs_recoding"=>false, "longitude"=>"-122.22763688128907", "latitude"=>"47.473764549319185", "human_address"=>"{\"address\":\"850 SW 7th St.\",\"city\":\"Renton\",\"state\":\"\",\"zip\":\"98057\"}"}, "minimum_volume"=>"no minimum", "mail_in_allowed"=>"TRUE", "service_description"=>"Anything with a cord on or anything with metal in it. Working or not or parts.", "provider_address"=>"850 SW 7th St.", "provider_name"=>"1 Green Planet"}
end

def location_json4
  {"zip"=>"98057", "maximum_volume"=>"no maximum", "phone"=>{"phone_number"=>"(425) 996-3513"}, "providerid"=>"710", "restrictions"=>"Pickup service available upon arragement, typically for quantity of ten items or more.  Please inquire. Call to arrange drop off.", "location"=>"850 SW 7th St. WA 98057", "dropoff_allowed"=>"TRUE", "hours"=>"Mon - Fri:  9:30am - 6:30pm", "pickup_allowed"=>"TRUE", "city"=>"Renton", "material_handled"=>"Refrigerators", "fee"=>"We provide free recycling to everyone !", "mapping_location"=>{"needs_recoding"=>false, "longitude"=>"-122.22809200647511", "latitude"=>"47.473790760173145", "human_address"=>"{\"address\":\"850 7th St\",\"city\":\"WA\",\"state\":\"\",\"zip\":\"98057\"}"}, "property_type"=>"Business, Residents", "geolocation"=>{"needs_recoding"=>false, "longitude"=>"-122.22763688128907", "latitude"=>"47.473764549319185", "human_address"=>"{\"address\":\"850 SW 7th St.\",\"city\":\"Renton\",\"state\":\"\",\"zip\":\"98057\"}"}, "minimum_volume"=>"no minimum", "mail_in_allowed"=>"TRUE", "provider_address"=>"850 SW 7th St.", "provider_name"=>"1 Green Planet"}
end
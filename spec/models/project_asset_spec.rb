require 'spec_helper'

describe ProjectAsset do
  subject { project_asset }
  let(:asset) { described_class.new }

  it "exists" do
    asset.class.should eq ProjectAsset
  end

  describe "#id" do
    it "exists as an attribute on a ProjectAsset" do
      asset.respond_to?(:id).should eq true
    end
  end

  describe "#project_asset_file_name" do
    it "exists as an attribute on a ProjectAsset" do
      asset.respond_to?(:project_asset_file_name).should eq true
    end
  end

  describe "#project_asset_file_type" do
    it "exists as an attribute on a ProjectAsset" do
      asset.respond_to?(:project_asset_file_type).should eq true
    end
  end

  describe "#project_asset_file_size" do
    it "exists as an attribute on a ProjectAsset" do
      asset.respond_to?(:project_asset_file_size).should eq true
    end
  end

  describe "#project_asset_updated_at" do
    it "exists as an attribute on a ProjectAsset" do
      asset.respond_to?(:project_asset_updated_at).should eq true
    end
  end

  describe "#project_id" do
    it "exists as an attribute on a ProjectAsset" do
      asset.respond_to?(:project_id).should eq true
    end
  end

  describe "#created_at" do
    it "exists as an attribute on a ProjectAsset" do
      asset.respond_to?(:created_at).should eq true
    end
  end

  describe "#updated_at" do
    it "exists as an attribute on a ProjectAsset" do
      asset.respond_to?(:updated_at).should eq true
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe GoogleDistanceMatrix::Configuration do
  include Shoulda::Matchers::ActiveModel

  subject { described_class.new }

  describe 'Validations' do
    describe 'departure_time' do
      it 'is valid with a timestamp' do
        subject.departure_time = Time.now.to_i
        subject.valid?
        expect(subject.errors[:departure_time].length).to eq 0
      end

      it 'is valid with "now"' do
        subject.departure_time = 'now'
        subject.valid?
        expect(subject.errors[:departure_time].length).to eq 0
      end

      it 'is invalid with "123now"' do
        subject.departure_time = '123now'
        subject.valid?
        expect(subject.errors[:departure_time].length).to eq 1
      end

      it 'is invalid with something else' do
        subject.departure_time = 'foo'
        subject.valid?
        expect(subject.errors[:departure_time].length).to eq 1
      end
    end

    describe 'arrival_time' do
      it 'is valid with a timestamp' do
        subject.arrival_time = Time.now.to_i
        subject.valid?
        expect(subject.errors[:arrival_time].length).to eq 0
      end

      it 'is invalid with something else' do
        subject.arrival_time = 'foo'
        subject.valid?
        expect(subject.errors[:arrival_time].length).to eq 1
      end
    end

    it { should validate_inclusion_of(:mode).in_array(%w[driving walking bicycling transit]) }
    it { should allow_value(nil).for(:mode) }

    it { should validate_inclusion_of(:avoid).in_array(%w[tolls highways ferries indoor]) }
    it { should allow_value(nil).for(:avoid) }

    it { should validate_inclusion_of(:units).in_array(%w[metric imperial]) }
    it { should allow_value(nil).for(:units) }

    it { should validate_inclusion_of(:protocol).in_array(%w[http https]) }

    describe 'http_open_timeout' do
      it 'is valid with a positive number' do
        subject.http_open_timeout = 1
        subject.valid?
        expect(subject.errors[:http_open_timeout].length).to eq 0
      end

      it 'is invalid with zero' do
        subject.http_open_timeout = 0
        subject.valid?
        expect(subject.errors[:http_open_timeout].length).to eq 1
      end

      it 'is invalid with a negative number' do
        subject.http_open_timeout = -1
        subject.valid?
        expect(subject.errors[:http_open_timeout].length).to eq 1
      end

      it { should allow_value(nil).for(:http_open_timeout) }
    end

    describe 'http_read_timeout' do
      it 'is valid with a positive number' do
        subject.http_read_timeout = 1
        subject.valid?
        expect(subject.errors[:http_read_timeout].length).to eq 0
      end

      it 'is invalid with zero' do
        subject.http_read_timeout = 0
        subject.valid?
        expect(subject.errors[:http_read_timeout].length).to eq 1
      end

      it 'is invalid with a negative number' do
        subject.http_read_timeout = -1
        subject.valid?
        expect(subject.errors[:http_read_timeout].length).to eq 1
      end

      it { should allow_value(nil).for(:http_read_timeout) }
    end

    describe 'http_ssl_timeout' do
      it 'is valid with a positive number' do
        subject.http_ssl_timeout = 1
        subject.valid?
        expect(subject.errors[:http_ssl_timeout].length).to eq 0
      end

      it 'is invalid with zero' do
        subject.http_ssl_timeout = 0
        subject.valid?
        expect(subject.errors[:http_ssl_timeout].length).to eq 1
      end

      it 'is invalid with a negative number' do
        subject.http_ssl_timeout = -1
        subject.valid?
        expect(subject.errors[:http_ssl_timeout].length).to eq 1
      end

      it { should allow_value(nil).for(:http_ssl_timeout) }
    end

    it { should validate_inclusion_of(:transit_mode).in_array(%w[bus subway train tram rail]) }
    it {
      should validate_inclusion_of(
        :transit_routing_preference
      ).in_array(%w[less_walking fewer_transfers])
    }
    it {
      should validate_inclusion_of(:traffic_model).in_array(%w[best_guess pessimistic optimistic])
    }
  end

  describe 'defaults' do
    it { expect(subject.mode).to eq 'driving' }
    it { expect(subject.avoid).to be_nil }
    it { expect(subject.units).to eq 'metric' }
    it { expect(subject.lat_lng_scale).to eq 5 }
    it { expect(subject.use_encoded_polylines).to eq false }
    it { expect(subject.protocol).to eq 'https' }
    it { expect(subject.language).to be_nil }

    it { expect(subject.departure_time).to be_nil }
    it { expect(subject.arrival_time).to be_nil }
    it { expect(subject.transit_mode).to be_nil }
    it { expect(subject.traffic_model).to eq 'best_guess' }

    it { expect(subject.google_business_api_client_id).to be_nil }
    it { expect(subject.google_business_api_private_key).to be_nil }
    it { expect(subject.google_api_key).to be_nil }

    it { expect(subject.logger).to be_nil }
    it { expect(subject.cache).to be_nil }

    # rubocop:disable Layout/LineLength
    it 'has a default expected cache_key_transform' do
      key = subject.cache_key_transform.call('foo')
      expect(key).to eq 'f7fbba6e0636f890e56fbbf3283e524c6fa3204ae298382d624741d0dc6638326e282c41be5e4254d8820772c5518a2c5a8c0c7f7eda19594a7eb539453e1ed7'
    end
    # rubocop:enable Layout/LineLength
  end

  describe '#to_param' do
    described_class::ATTRIBUTES.each do |attr|
      it "includes #{attr}" do
        subject[attr] = 'foo'
        expect(subject.to_param[attr]).to eq subject.public_send(attr)
      end

      it "does not include #{attr} when it is blank" do
        subject[attr] = nil
        expect(subject.to_param.with_indifferent_access).to_not have_key attr
      end
    end

    described_class::API_DEFAULTS.each_pair do |attr, default_value|
      it "does not include #{attr} when it equals what is default for API" do
        subject[attr] = default_value

        expect(subject.to_param.with_indifferent_access).to_not have_key attr
      end
    end

    it 'includes client if google_business_api_client_id has been set' do
      subject.google_business_api_client_id = '123'
      expect(subject.to_param['client']).to eq '123'
    end

    it 'includes key if google_api_key has been set' do
      subject.google_api_key = '12345'
      expect(subject.to_param['key']).to eq('12345')
    end
  end
end

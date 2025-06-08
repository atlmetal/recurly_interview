#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/inline'
gemfile do
  source 'https://rubygems.org'
  gem 'builder'
  gem 'webrick'
end

require 'webrick'

ABNS = {
  '10120000004' => {
    name: 'Example Company Pty Ltd',
    gst: true,
    effective_to: '2025-04-01',
    address: {
      state: 'NSW',
      postcode: '2000'
    }
  },
  '10000000000' => {
    name: 'Example Company Pty Ltd 2',
    gst: false,
    effective_to: '2024-09-01',
    address: {
      state: 'NSW',
      postcode: '2001'
    }
  }
}.freeze

def format_response(abn)
  xml = Builder::XmlMarkup.new
  xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'

  xml.abn_response do
    xml.request do
      xml.identifiersearchrequest do
        xml.abn abn
      end
    end

    xml.response do
      yield xml
    end
  end
end

class ABNValidator < WEBrick::HTTPServlet::AbstractServlet
  def service(request, response)
    response.content_type = 'application/xml'
    abn = request.query['abn']&.tap(&:strip!)

    if abn.nil? || abn.empty?
      response.status = 400
      response.body = format_response(abn) do |xml|
        xml.error 'ABN is required'
      end
      return
    end

    if abn == '53004085616'
      response.status = 500
      return
    end

    business = ABNS[abn.gsub(/\D/, '')]
    unless business
      response.status = 404
      response.body = format_response(abn) do |xml|
        xml.businessEntity nil
      end
      return
    end

    response.body = format_response(abn) do |xml|
      xml.dateRegisterLastUpdated '2024-04-01'
      xml.dateTimeRetrieved Time.now.iso8601
      xml.businessEntity do
        xml.abn abn
        xml.status 'Active'
        xml.entityType 'Company'
        xml.organisationName business[:name]
        xml.goodsAndServicesTax business[:gst]
        xml.effectiveTo business[:effective_to]
        xml.address do
          xml.stateCode business[:address][:state]
          xml.postcode business[:address][:postcode]
        end
      end
    end
  end
end

server = WEBrick::HTTPServer.new(Port: 8080)
server.mount '/queryABN', ABNValidator

trap 'INT' do server.shutdown end
trap 'TERM' do server.shutdown end

server.start

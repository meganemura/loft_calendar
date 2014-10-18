# coding: utf-8

require 'date'
require 'open-uri'
require 'nokogiri'
require 'icalendar'
require 'chronic'

module LoftCalendar

  def self.new(live_house)
    Calendar.new(live_house)
  end

  class Calendar
    def initialize(live_house)
      @live_house = live_house
    end

    def generate
      @calendar = Icalendar::Calendar.new

      today = Date.today

      crawler = LoftCalendar::Crawler.new(@live_house, today.year, today.month)
      events = crawler.to_events.map(&:to_ical_event)
      events.each do |event|
        @calendar.add_event(event)
      end

      nil
    end

    def to_ical
      @calendar.to_ical
    end
  end

  class Crawler

    LOFT      = 'plusone'.freeze    # LOFT
    SHELTER   = 'shelter'.freeze    # Shelter
    PLUSONE   = 'plusone'.freeze    # LOFT/PLUS ONE
    NAKED     = 'naked'.freeze      # Naked Loft
    LOFTA     = 'lofta'.freeze      # Asagaya Loft A
    WEST      = 'west'.freeze       # Loft PlusOne West
    BROADCAST = 'broadcast'.freeze  # Loft Channel

    LIVE_HOUSES = [
      LOFT, SHELTER, PLUSONE, NAKED, LOFTA, WEST, BROADCAST
    ]

    def initialize(live_house = LOFT, year = 2014, month = 1)
      unless LIVE_HOUSES.include?(live_house.to_s)
        raise ArgumentError
      end

      @live_house = live_house.to_s
      @year       = year.to_s
      @month      = month.to_s.rjust(2, '0')
    end

    # TODO: Move to appropriate class
    def to_events
      dates.inject([]) do |array, node|
        day = node.css('th.day').text[/\d+/].to_i
        events = node.css('td.event_box > div.event')

        events.each do |event|
          array << Event.new(2014, 10, day, event)
        end

        array
      end
    end

    # TODO: Move to appropriate class
    def dates
      document.css('table.timetable > tr')
    end

    def document
      @document ||= Nokogiri.HTML(html)
    end

    def html
      @html ||= open(url)
    end

    def url
      "http://www.loft-prj.co.jp/schedule/#{@live_house}/date/#{@year}/#{@month}"
    end

    class Event
      attr_reader :year, :month, :day, :node
      def initialize(year, month, day, node)
        @year  = year
        @month = month
        @day   = day
        @node  = node
      end

      def to_ical_event
        Icalendar::Event.new.tap do |e|
          e.summary     = summary
          e.description = [description, ticket].join("\n")
          start_at      = Chronic.parse("#{year}-#{month}-#{day} #{time_open}")
          e.dtstart     = Icalendar::Values::DateTime.new(start_at)
          e.dtend       = Icalendar::Values::DateTime.new(start_at + 3 * 60 * 60)
          e.url         = url
        end
      end

      def summary
        node.css('h3 > a').text
      end

      def description
        node.css('p.month_content').text.gsub(/<br>/, '')
      end

      def url
        node.css('h3 > a').first.attributes["href"].value
      end

      def time_open
        time_text[/OPEN\s(\d{2}:\d{2})/, 1]
      end

      def time_start
        time_text[/START\s(\d{2}:\d{2})/, 1]
      end

      # TODO: parse
      # => "OPEN 18:30 / START 19:30"
      def time_text
        node.css('p.time_text').text
      end

      def ticket
        node.css('p.ticket').text.gsub(/<br>/, '')
      end

      def inspect
        "#<LoftCalendar::Event: #{@year}/#{@month}/#{@day}>"
      end
    end
  end
end

# loft_calendar

ロフト系列のお店のスケジュールを iCal 形式で出力する。

## Usage

```ruby
calendar = LoftCalendar.new('plusone')  # See `LoftCalendar::Crawler::LIVE_HOUSES`
calendar.generate
ical = calendar.to_ical
File.open('/path/to/loft.ics', 'w') { |f| f.write(calendar.to_ical) }
```

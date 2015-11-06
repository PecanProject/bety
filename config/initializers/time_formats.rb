module DateTimeConstants
  Seasons = ['Season: MAN', 'Season: JJA', 'Season: SON', 'Season: DJF']
  SeasonRepresentativeMonths = { 'Season: MAN' => 4, 'Season: JJA' => 7, 'Season: SON' => 10, 'Season: DJF' => 1 }
  TimesOfDay = ['morning', 'mid-day', 'afternoon', 'night']
  TimesOfDayRepresentativeHours = { 'morning' => 9, 'mid-day' => 12, 'afternoon' => 15, 'night' => 0 }

  Months = 1..12
  Days = 1..31
  Hours = 0..23
  Minutes = 0..59
end

NEW_FORMATS = {

  # Date Formats

  # dateloc 9
  no_date_data: '[date unspecified or unknown]',

  # dateloc 8
  year_only: '%Y',

  # dateloc 7
  season_and_year: ->(date) do
    date.strftime("#{date.to_s(:season_only)} %Y")
  end,

  # dateloc 6
  month_and_year: '%B %Y',

  # dateloc 5.5:
  week_of_year: 'Week of %b %-d, %Y',

  # dateloc 5:
  year_month_day: '%Y %b %-d',

  # dateloc 97:
  season_only: ->(date) do
    DateTimeConstants::SeasonRepresentativeMonths.key(date.month) ||
      '[Invalid season designation]'
  end,

  # dateloc 96:
  month_only: '%B',

  # dateloc 95:
  month_day: ->(date) { date.strftime("%B #{date.day.ordinalize}") },

  unspecified_dateloc: 'Date Level of Confidence Unknown',

  unrecognized_dateloc: 'Unrecognized Value for Date Level of Confidence',


  # Time Formats

  # timeloc 9:
  no_time_data: '[time unspecified or unknown]',
  
  # timeloc 4:
  time_of_day: ->(time) do
    case time.hour
    when 0
      'night'
    when 9
      'morning'
    when 12
      'mid-day'
    when 15
      'afternoon'
    else
      '[Invalid time-of-day designation]'
    end
  end,

  # timeloc 3:
  hour_only: '%l %p',

  # timeloc 2:
  hour_minutes: '%H:%M',

  # timeloc 1:
  hour_minutes_seconds: '%H:%M:%S',

  unspecified_timeloc: 'Time Level of Confidence Unknown',

  unrecognized_timeloc: 'Unrecognized Value for Time Level of Confidence'



}


Time::DATE_FORMATS.merge!(NEW_FORMATS)


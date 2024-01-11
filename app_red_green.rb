# app.rb
require 'sinatra'
require 'csv'
require 'chartkick'

set :bind, '0.0.0.0'
set :port, 4567
set :public_folder, __dir__ + '/public'


get '/' do
  readCSV
  aggregate_stats
  erb :chart
end

def stddev(ary)
  ary.map! { |elt| elt.to_f } # String can't be coerced into Float .. so map all vals to float in place
  
  # why am i using Arra#sum ? .. OK ..
  # Using the #sum method from Array is many, many times faster than using the alternative, inject.
  # The #sum method was only added to Array in Ruby 2.4, which is why you might see alternative implementations in other places on the Internet.

  ary_size = ary.size
  ary_sum = ary.sum(0.0)
  mean = ary_sum / ary_size
  sum = ary.sum(0.0) { |element| (element - mean) ** 2 }
  variance = sum / (ary.size - 1)
  standard_deviation = Math.sqrt(variance)

end

def readCSV
  @data = CSV.read(File.expand_path('~/data/log/speedtest/speedtest.csv'), headers: true)
end

def aggregate_stats
  @total_point_count = 0
  @download_lo_count = 0
  @download_hi_count = 0

  @download_values = []
  strks = []
  @normal_availability_speed_sla = 0
  @normal_availability_speed_fail = 0

  @data.each do |row|
    datetime = row['DATETIME']
    download_lo = row['DOWNLOADLOW']
    download_hi = row['DOWNLOADHI']
    @download_values << download_lo unless download_lo.to_i == 0
    @download_values << download_hi unless download_hi.to_i == 0

    if (download_hi.to_i >= 505) 
      @normal_availability_speed_sla += 1 
    else 
      @normal_availability_speed_fail += 1
    end
   
    upload = row['UPLOAD']
    sla_value = row['SLA']

    sla = download_hi.to_i > 0 ? true : false # download Mbits/s is greater than SLA then 'sla' is true as it has been met
   
    @download_lo_count += 1 unless sla
    @download_hi_count += 1 if sla

    if (sla)
      strks << 1
    else
      strks << 0
    end

    @total_point_count += 1
  end
  @percent_sla = @download_hi_count.to_f / @total_point_count.to_f
  @percent_fail = @download_lo_count.to_f / @total_point_count.to_f
  
  strks_string = strks.join('')
  fails_string = strks_string
  strks_string = strks_string.gsub(/0+/, '0')
  fails_string = fails_string.gsub(/1+/, '1')
  @strks_ary = strks_string.split('0').sort.reverse
  @fails_ary = fails_string.split('1').sort.reverse
  @streak_count = {}
  @fails_count = {}
  @strks_ary.each do |elt|
    if (elt.length >= 4) # a streak is more than 4 in a row
      key = "#{elt.length * 5}m"
      @streak_count[key] = (@streak_count[key].nil?) ? 1 : @streak_count[key] + 1
    end
  end
  @fails_ary.each do |elt|
    if (elt.length >= 4) # a streak is more than 4 in a row
      key = "#{elt.length * 5}m"
      @fails_count[key] = (@fails_count[key].nil?) ? 1 : @fails_count[key] + 1
    end
  end
  streak_count_values_sum = @streak_count.values.sum
  fails_count_values_sum = @fails_count.values.sum
  streaks_total_count = streak_count_values_sum + fails_count_values_sum

  @streak_count_sla_percent  = streak_count_values_sum.to_f / streaks_total_count
  @streak_count_fail_percent = fails_count_values_sum.to_f / streaks_total_count
  
  # let's use some beautiful ruby sugar to calculate days, hours, minutes of given duration in sconds
  # @total_point_count * 5 will give total_seconds
  total_seconds = @total_point_count * 5 * 60                                  # number of seconds  
  @time_span = Time.at(total_seconds).utc.strftime("%H:%M:%S")

  mm, ss = total_seconds.divmod(60)
  hh, mm = mm.divmod(60)
  dd, hh = hh.divmod(24)
  @sample_span_dhms = "%d days, %d hours, %d minutes and %d seconds" % [dd, hh, mm, ss]
 
  @standard_deviation = stddev(@download_values) 
end


__END__

@@ chart
<!DOCTYPE html>
<html>
<head>
  <script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
  <script type="text/javascript">
    google.charts.load('current', {'packages':['corechart']});
    google.charts.setOnLoadCallback(drawChart);

    function drawChart() {
      var data = new google.visualization.DataTable();
      data.addColumn('string', 'DATETIME');
      data.addColumn('number', 'DOWNLOADLOW');
      data.addColumn('number', 'DOWNLOADHI');
      data.addColumn('number', 'UPLOAD');
      data.addColumn('number', 'SLA');
      data.addRows([
        <% @data.each do |row| %>
          ['<%= row['DATETIME'] %>', <%= row['DOWNLOADLOW'] %>,<%= row['DOWNLOADHI'] %> ,<%= row['UPLOAD'] %>, <%= row['SLA'] %>],
        <% end %>
      ]);

      var options = {
        title: 'Speedtest Data',
        curveType: 'none',
        legend: { position: 'bottom' },
        pointSize: 1,
        hAxis: {title: 'Datetime 5m buckets'},
        vAxis: {title: 'MBps'},
        series: {
                  0: { color: '#ff0000',
                       lineWidth: 1,
                       pointSize: 2 },
                  1: { color: '#0fff0f',
                       lineWidth: 1,
                       pointSize: 2 },
                  2: { color: '#0000ff' },
                  3: { color: '#777777' }
        }
      };
      
      // Loop through each row to set colors based on DOWNLOAD values
      for (var i = 0; i < data.getNumberOfRows(); i++) {
        var downloadValue = data.getValue(i, 1);
        var uploadValue = data.getValue(i, 2);
      
        // Set colors based on the condition for DOWNLOAD and UPLOAD
        var downloadColor = downloadValue > 258 ? '#00FF00' : '#FF0000';  // Adjusted this line
        var uploadColor = uploadValue > 258 ? '#FF0000' : '#FF0000';
      
        // Set the color for the data points
        data.setRowProperty(i, 'style', 'point { stroke-color: ' + downloadColor + '; fill-color: ' + downloadColor + '; }');
        data.setRowProperty(i, 'style', 'point { stroke-color: ' + downloadColor + '; fill-color: ' + downloadColor + '; }');
        data.setRowProperty(i, 'style', 'point { stroke-color: ' + uploadColor + '; fill-color: ' + uploadColor + '; }');
      }
      
      var chart = new google.visualization.LineChart(document.getElementById('chart_div'));
      chart.draw(data, options);


    }
  </script>

  <style>
  /* Tooltip container */
  .tooltip {
    position: relative;
    display: inline-block;
    border-bottom: 1px dotted black; /* If you want dots under the hoverable text */
  }
  
  /* Tooltip text */
  .tooltip .tooltiptext {
    visibility: hidden;
    width: 120px;
    background-color: black;
    color: #fff;
    text-align: center;
    padding: 5px 0;
    border-radius: 6px;
   
    /* Position the tooltip text - see examples below! */
    position: absolute;
    z-index: 1;
  }
  
  /* Show the tooltip text when you mouse over the tooltip container */
  .tooltip:hover .tooltiptext {
    visibility: visible;
  }
    .red
    {
      color:red;
    }
    .green
    {
      color:green;
    }
    .blue
    {
      color:blue;
    }
    .td80percent {
      max-width: 300px; // Desired max width
      width: max-content;
    }
    body {
      margin: 10px;
    }
    
    main {
      min-height: calc(100vh - 4rem);
    }
    .bottom_div_height {
      height: 10rem; 
    }
    footer {
      height: -10rem;
      position: fixed;
      bottom: 0;
      margin-left: 10px;
      margin-right: 10px;
      margin-top: 10px;
      text-align: right;
      display: block;
    }
    .right_text {
      text-align: right;
    }
    .description {
      margin-top: 50px;
      margin-bottom: 50px;
    }
    .metric_description {
      color: "#555555";
    }
    table{
      table-layout: fixed;
      border: 1px solid black;
      border-collapse: collapse;
    }
    td{
      word-wrap:break-word;
      max-width: 25%;
      border: 1px solid black;
      border-collapse: collapse;
    }
    th {
      word-wrap:break-word;
      border: 1px solid black;
      border-collapse: collapse;
      background-color: lightgrey;
    }
    tr:nth-child(even) {
      background-color: #f2f2f2;
      border: 1px solid black;
      border-collapse: collapse;
    }
    .desc_width {
      max-width: 150px; 
      word-wrap: break-word;
    }
    .width_500px {
      width: 500px;
    }
  </style>
</head>
<body>
  <main>
    <h1>Speedtest Data Visualization</h1>
    <div class="description" id="chart_div" style="height: 500px; width: 95%"></div>
    <div id="chart_div_description">
      <span id="chart_div_description_span">
        This chart shows Speedtest results of samples taken every 5 minute. The Y-axis or height of the point indicates the value for Mbits/s at the time the sample was measured.
      </span>
        <ul id="chart_div_description_span_ul">
          <li>DOWNLOADLOW is in <span class="red">RED</span>. Any sample that has a value which is less than the published SLA (258 Mbits/s) is part of this series.</li>
          <li>DOWNLOADHI is in <span class="green">GREEN</span>. Any sample that has a value which equals or exceeds the published SLA is part of this series.</li>
          <li>UPLOAD is in <span class="blue">BLUE</span>.</li>
        </ul>
    </div>
    <div>
      <span>
        <table>
          <tr>
            <th>Metric</th>
            <th>Value</th>
            <th class="width_500px">Description</th>
            <th class="width_500px">Information</th>
          </tr> 
  
          <tr>
            <td>Sample Span</td>
            <td class="td80percent"><%= @sample_span_dhms %></div></td>
            <td><span class="metric_description">The span of time covered by these metrics.</span></td>
            <td rowspan="9"><div class="td80percent"><img width="500" height="300" src="img/virgin_media_service_summary.png"></img></div></td>
          </tr> 
          <tr>
            <td>Total point count</td>
            <td class="td80percent"><%= @total_point_count %></div></td>
            <td><span class="metric_description">The total count of the 5 minute samples present in the metric calculations.</span></td>
            <td></td>
          </tr> 
          <tr>
            <td>Within Normal Avaiability count</td>
            <td class="td80percent"><%= @normal_availability_speed_sla %></div></td>
            <td><span class="metric_description">Speeds in the normal zone</span></td>
            <td></td>
          </tr> 
          <tr>
            <td>Fail Normal Available Speed</td>
            <td class="td80percent"><%= @normal_availability_speed_fail %></div></td>
            <td><span class="metric_description">Speeds below the normal zone</span></td>
            <td></td>
          </tr> 
          <tr>
            <td>Below SLA count</td>
            <td><div class="td80percent"><%= @download_lo_count %></div></td>
            <td><span class="metric_description">The count of 5 minute samples that fall below the published SLA value of 258 Mbits/s</span></td>
            <td></td>
          </tr> 
          <tr>
            <td>Above SLA count</td>
            <td></span><div class="td80percent"><%= @download_hi_count %></div></td>
            <td><span class="metric_description">The count of 5 minute samples that fall within the published 258 Mbit/s SLA.</span></td>
            <td></td>
          </tr> 
          <tr>
            <td>Standard Deviationve SLA count</td>
            <td></span><div class="td80percent"><%= @standard_deviation %></div></td>
            <td><span class="metric_description">The Standard Deviation of the whole set of Download times</span></td>
            <td></td>
          </tr> 
          <tr>
            <td>Percent Within SLA</td>
            <td><div class="td80percent"><%= sprintf('%0.2f' '%%', @percent_sla.to_f*100) %></div></td>
            <td><span class="metric_description">The percentage of all 5 minute samples that meet the SLA criterion (258 Mbits/s Download).</span></td>
            <td></td>
          </tr> 
          <tr>
            <td>Percent Failing to meet SLA</td>
            <td><div class="td80percent"><%= sprintf('%0.2f' '%%', @percent_fail.to_f*100) %></div></td>
            <td><span class="metric_description">The percentage of all 5 minute samples that fail meet the SLA criterion.</span></td>
            <td></td>
          </tr> 
          <tr>
            <td>Streak Percent within SLA</td>
            <td><div class="td80percent"><%= sprintf('%0.2f' '%%', @streak_count_sla_percent.to_f*100) %></div></td>
            <td><span class="metric_description">The percentage of all Streaks (4 or more 5 minute samples in a row)  that meet the SLA criterion.</span></td>
            <td></td>
          </tr> 
          <tr>
            <td>Streak Percent Failing to meet SLA</td>
            <td><div class="td80percent"><%= sprintf('%0.2f' '%%', @streak_count_fail_percent.to_f*100) %></div></td>
            <td><span class="metric_description">The percentage of all Streaks (I'm being generous with a 20 minute Streak rather than an hour, which is the standard bookable amount of time,
                but then Virgin would not even have single Streak) that fail meet the SLA criterion.</span></td>
            <td></td>
          </tr> 
          <tr>
            <td>Within SLA Streaks</td> 
            <td><div class="td80percent"><%= @streak_count %></div></td>
            <td>
              <span class="metric_description">
                Streaks that fall within the SLA.
              </span>
            </td>
            <td></td>
          </tr> 
          <tr>
            <td>Fail SLA Streaks</td>
            <!--<td><div class="tooltip"><span class="tooltiptext"><%= @fails_count %></span></div></td>-->
            <td><div class="td80percent"><%= @fails_count %></div></td>
            <td>
              Streaks failing to meet the SLA. A 'Streak' is defined herein as 3 or more contiguous 5 minute samples. 
              This value is a hash of Streak Length in minutes :: Count of the number of streaks of that duration.
            </td>
            <td></td>
          </tr> 
        </table>
      </span>
    </div>
    <div class="bottom_div_height"> </div>
  </main>
  <footer style="text-align: right;">
  <div class="right_text">
    Copyleft <a href="mailto:morgan@morganism.dev">morganism</a>. All rights reversed. <a target="_blank" href="https://git.morganism.dev/osx-utils/tree/master/speedtest/rare_medium/visualise/">GitHub source</a>
  </div>
  </footer>
</body>
</html>


#!/bin/bash

# Prompt for 'bin' directory path
read -p "📁 Enter the path to your 'bin' directory: " bin_path

# Verify the presence of the scripts
if [ ! -f "$bin_path/speedtest.simple" ] || [ ! -f "$bin_path/parse.speedtest.simple_to_csv" ]; then
  echo "❌ One or both scripts not found in the specified 'bin' directory. Please ensure they are present and try again."
  exit 1
fi

# Add cron entries
(crontab -l ; echo "0 */4 * * * $bin_path/speedtest.simple") | crontab -
(crontab -l ; echo "0 */6 * * * $bin_path/parse.speedtest.simple_to_csv") | crontab -

echo "✅ Cron entries added successfully!"



#!/bin/bash

# help setup requirements

# Initial assessment
echo "🔍 Checking system status..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  echo "✅ Operating System: MacOS"
  package_manager="brew"
elif [[ "$OSTYPE" == "linux-gnu" ]]; then
  echo "✅ Operating System: Linux"
  package_manager="apt-get"
else
  echo "❌ Unsupported operating system. Script supports MacOS and Linux."
  exit 1
fi

read -p "🚀 Do you want to proceed with the setup? (yes/no): " proceed
if [ "$proceed" != "yes" ]; then
  echo "🛑 Setup aborted."
  exit 0
fi

# Install Ruby if not present
if ! command -v ruby &> /dev/null; then
  read -p "🔧 Ruby is required but not found. Do you want to install Ruby? (yes/no): " install_ruby
  if [ "$install_ruby" == "yes" ]; then
    echo "🛠️ Installing Ruby..."
    sudo $package_manager update
    sudo $package_manager install ruby-full
  else
    echo "❌ Ruby is required. Setup aborted."
    exit 0
  fi
fi

# Install Oookla Speedtest and speedtest-cli
if ! command -v speedtest &> /dev/null; then
  read -p "🔧 Oookla Speedtest not found. Do you want to install it? (yes/no): " install_speedtest
  if [ "$install_speedtest" == "yes" ]; then
    echo "🛠️ Installing Oookla Speedtest..."
    sudo $package_manager install speedtest
  else
    echo "❌ Oookla Speedtest is required. Setup aborted."
    exit 0
  fi
fi

# Continue with installing speedtest-cli
if ! command -v speedtest-cli &> /dev/null; then
  read -p "🔧 speedtest-cli not found. Do you want to install it? (yes/no): " install_speedtest_cli
  if [ "$install_speedtest_cli" == "yes" ]; then
    echo "🛠️ Installing speedtest-cli..."
    sudo $package_manager install speedtest-cli
  else
    echo "❌ speedtest-cli is required. Setup aborted."
    exit 0
  fi
fi

echo "🚀 Setup completed successfully!"



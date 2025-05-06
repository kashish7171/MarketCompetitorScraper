#!/bin/bash

# Project directory
PROJECT="/mnt/d/_Aman/_Projects/PY - PHP/PY/2025/Apr/MarketCompetitorScraper"
cd "$PROJECT" && cd ..

# Ensure that the virtual environment is activated (if you're using one)
source wsl_env/bin/activate

# Path to your log directory and the log file
LOG_DIR="$PROJECT/logs"
LOG_FILE="$LOG_DIR/pricing.from.google.main.right.side.log"

# Path to the shell log file
SHELL_LOG_FILE="$PROJECT/shell.log"
rm -rf "$SHELL_LOG_FILE"rt4

# Function to check if the scraper process is running
check_process() {
    pgrep -f "python3 app.py" > /dev/null
    return $?
}

# Function to kill processes matching the "python3 app.py" pattern
kill_processes() {
    pkill -f "python3 app.py"
    if [ $? -eq 0 ]; then
        log_message "All scraper processes have been killed."
    else
        log_message "No scraper processes found to kill."
    fi
}

# Fucntion to insert log
log_message() {
    local message="$1"
    local timestamp=$(date '+%b %d, %Y %H:%M:%S')
    echo "$(date '+%d %b, %Y %H:%M:%S') - $message" >> "$SHELL_LOG_FILE"
    # echo "$(date '+%d %b, %Y %H:%M:%S') - $message"
}

# Function to check if the process is stuck (i.e., not progressing)
check_if_stuck() {
    # Check if the process is running but has been running for too long (e.g., more than 3 minutes)
    stuck_process=$(ps -eo pid,etime,comm | grep "python3 app.py" | grep -v grep)
    
    if [ -n "$stuck_process" ]; then
        # Extract the elapsed time of the process
        elapsed_time=$(log_message $stuck_process | awk '{print $2}')
        
        # Convert elapsed time to minutes (this is a simple approach, you may need a more complex one)
        if [[ "$elapsed_time" =~ [0-9]+:[0-9]+ ]]; then
            # Check if the elapsed time is over 3 minutes
            minutes=$(log_message $elapsed_time | cut -d ":" -f1)
            if [ "$minutes" -gt 3 ]; then
                return 0  # True, Process is stuck
            fi
        fi
    fi
    
    return 1  # False, Process is not stuck
}

# Function to check if log file was modified in the last 30 minutes
check_log_last_modified() {
    # Get the last modified time of the log file in seconds
    last_modified=$(stat -c %Y "$LOG_FILE")
    
    # Get the current time in seconds
    current_time=$(date +%s)
    
    # Calculate the difference in seconds
    let time_diff=current_time-last_modified

    # Return the time difference
    echo $time_diff
}

# Function to delete the log directory
delete_log_directory() {
    if [ -d "$LOG_DIR" ]; then
        log_message "Deleting log directory..."
        rm -rf "$LOG_DIR"  # This will remove the directory and all its contents
    fi
}

# Function to restart the script instead of rebooting
restart_script() {
    log_message "Restarting the script: Killing all running processes and relaunching..."
    
    # Kill all running instances of the scraper
    pkill -f "python3 app.py"
    
    # Wait a bit to ensure processes are killed
    sleep 5

    # Relaunch this script
    exec bash "$0"
}

# Check if the argument "RE" is passed
if [ "$1" == "RE" ]; then
    kill_processes
fi
# Run the scraping process if it's not already running
if ! check_process; then
    log_message "'Google Main Right Side' scraper is not running. Starting..."
    cd "$PROJECT" && python3 app.py &
    log_message "'Google Main Right Side' scraper started."

    sleep 180

    # Start the loop to monitor the process every minute
    while true; do
        # Check if the scraping process is still running
        if ! check_process; then
            log_message "'Google Main Right Side' scraper is not running. Checking if it is stuck..."

            # Check if the process is stuck
            if check_if_stuck; then
                log_message "Process seems stuck. Waiting for 3 minutes before re-checking..."
                sleep 180

                # Recheck if the process is still stuck after waiting
                if check_if_stuck; then
                    log_message "Process is still stuck after waiting 3 minutes. Rebooting the server..."
                    restart_script
                else
                    # If the process is no longer stuck
                    log_message "'Google Main Right Side' scraper seems fine after waiting 3 minutes..."
                fi
            else
                # If the process finished normally, start the scraper again
                log_message "Process finished. Restarting the process..."
                cd "$PROJECT" && python3 app.py &
                log_message "'Google Main Right Side' scraper started."
            fi
        else
            log_message "'Google Main Right Side' scraper is still running."

            # Get the time difference since the log file was last modified
            time_diff=$(check_log_last_modified)
            log_message "Last modified time: $time_diff"

            # If the time difference is greater than 1800 seconds (30 minutes), the file has not been updated recently
            if [ "$time_diff" -gt 1800 ]; then
                log_message "Log files hasn't been updated in the last 30 minutes. Deleting log directory and rebooting the server..."
                delete_log_directory
                restart_script
            fi
        fi
        sleep 60
    done
else
    log_message "'Google Main Right Side' scraper is already running."
    
    # Get the time difference since the log file was last modified
    time_diff=$(check_log_last_modified)
    log_message "Last modified time: $time_diff"

    # If the time difference is greater than 1800 seconds (30 minutes), the file has not been updated recently
    if [ "$time_diff" -gt 1800 ]; then
        log_message "Log files hasn't been updated in the last 30 minutes. Deleting log directory and rebooting the server..."
        delete_log_directory
        restart_script
    fi
fi
function temp_monitor(a, analogPin, greenPin, yellowPin, redPin)
    %TEMP_MONITOR monitors the temperature in real time and displays the status with LEDs and plots.
    %   temp_monitor(a, analogPin, greenPin, yellowPin, redPin)
    %   Continuously reads the temperature from the specified analogPin, using the connection to the greenPin.
    %   The LEDs for yellowPin, redPin show the temperature status (green: normal, red: Excessive flicker )and plots the temperature profile in real time.
    %   Press Ctrl+C to stop.
    %
    %   Inputs:
    %       a          - Connected Arduino Objects。
    %       analogPin  - Connect the analog pins of the temperature sensor ( 'A0')
    %       greenPin   - Digital pin to connect to the green LED ('D9')
    %       yellowPin  - Connect the digital pins of the yellow LED ('D10').
    %       redPin     - Connect the digital pin of the red LED ('D11').
    %
    %   (Task 2g: Documentation)

    disp('Initialize the temperature monitor...');

    % Definition of constants
    Tc = 0.010;             % temperature coefficient (V/°C) for MCP9700A
    Vo0C = 0.500;           % Output Voltage (V) at 0°C for MCP9700A
    TEMP_LOW_THRESHOLD = 18;  % °C
    TEMP_HIGH_THRESHOLD = 24; % °C
    LOOP_TARGET_TIME = 1.0;   % Target cycle time (sec)
    YELLOW_BLINK_INTERVAL = 0.5; % sec
    RED_BLINK_INTERVAL = 0.25;   % sec
    PLOT_BUFFER_SIZE = 300;   % Plot buffer size 

    % Initializing state variables
    yellowState = 0; % 0=OFF, 1=ON
    redState = 0;    % 0=OFF, 1=ON
    lastYellowToggleTime = tic; % Record the last time the yellow LED switched state
    lastRedToggleTime = tic;    % Record the last time the red LED switched state

    % Initialization of drawings 
    fig = figure; % Creating a Graphics Window
    ax = axes(fig); % Creating Axes
    timeBuffer = NaN(1, PLOT_BUFFER_SIZE);
    tempBuffer = NaN(1, PLOT_BUFFER_SIZE);
    plotHandle = plot(ax, timeBuffer, tempBuffer, '-b'); % Plotting initial null data
    xlabel(ax, 'Time (s)');
    ylabel(ax, 'Temperature (°C)');
    title(ax, 'Real-time cabin temperature monitoring');
    grid(ax, 'on');
    ylim(ax, [10 35]); % Sets the initial Y-axis range, which can be adjusted as needed.
    dynamicXLim = true; % Whether to dynamically adjust the X-axis
    startTime = tic; % Recording program start time
    dataIndex = 0; % data point counter

    % Initialization of LEDs
    writeDigitalPin(a, greenPin, 0);
    writeDigitalPin(a, yellowPin, 0);
    writeDigitalPin(a, redPin, 0);
    disp('LED initialization complete (all off).');

    % Set up cleanup tasks (make sure LEDs are turned off when Ctrl+C exits)
    cleanupObj = onCleanup(@() cleanupFunction(a, greenPin, yellowPin, redPin, fig));
    disp('Enter the main monitoring loop (press Ctrl+C to stop)...');

    % Main monitoring loop
    while true % Infinite loop until user interrupt (Ctrl+C)
        loopStartTime = tic; % Record the current loop start time

        try
            % 1. Temperature reading
            voltage = readVoltage(a, analogPin);
            currentTemp = (voltage - Vo0C) / Tc;

            % 2. Recording data (using circular buffer)
            dataIndex = dataIndex + 1;
            bufferIndex = mod(dataIndex - 1, PLOT_BUFFER_SIZE) + 1;
            currentTime = toc(startTime); % Get the total time relative to the start
            timeBuffer(bufferIndex) = currentTime;
            tempBuffer(bufferIndex) = currentTemp;

            % 3. Updating of mapping data
            % In order to draw the circular buffer correctly, it is necessary to reorder or process the NaN
            validIndices = ~isnan(timeBuffer);
            sortedTime = timeBuffer(validIndices);
            sortedTemp = tempBuffer(validIndices);
            [sortedTime, sortOrder] = sort(sortedTime); % chronological
            sortedTemp = sortedTemp(sortOrder);

            set(plotHandle, 'XData', sortedTime, 'YData', sortedTemp);

            % Dynamically adjusts the X-axis range (displays data from the most recent period)
            if dynamicXLim && currentTime > PLOT_BUFFER_SIZE * LOOP_TARGET_TIME * 0.8 % Adjustment starts when the buffer is almost full
                set(ax, 'XLim', [max(0, currentTime - PLOT_BUFFER_SIZE*LOOP_TARGET_TIME), currentTime + LOOP_TARGET_TIME*10]); % Display last N seconds
            elseif dynamicXLim % Initialize X-axis
                 set(ax, 'XLim', [0, PLOT_BUFFER_SIZE*LOOP_TARGET_TIME]);
                 dynamicXLim = false; % Avoid setting it every time
            end

            drawnow limitrate; % Update graphs, limitrate to avoid too much frequency

            % 4. LED Control Logic
            if currentTemp >= TEMP_LOW_THRESHOLD && currentTemp <= TEMP_HIGH_THRESHOLD
                % Temperature normal
                writeDigitalPin(a, greenPin, 1); % Green light always on
                % Turn off other lights and reset status
                if yellowState == 1, writeDigitalPin(a, yellowPin, 0); yellowState = 0; end
                if redState == 1, writeDigitalPin(a, redPin, 0); redState = 0; end

            elseif currentTemp < TEMP_LOW_THRESHOLD
                % Under-temperature
                writeDigitalPin(a, greenPin, 0); % Turn off the green light.
                if redState == 1, writeDigitalPin(a, redPin, 0); redState = 0; end % Turn off the red light.

                % Handling yellow light blinking
                if toc(lastYellowToggleTime) >= YELLOW_BLINK_INTERVAL
                    yellowState = ~yellowState; % Toggle state (0 to 1, 1 to 0)
                    writeDigitalPin(a, yellowPin, yellowState);
                    lastYellowToggleTime = tic; % reset timer
                end

            else % currentTemp > TEMP_HIGH_THRESHOLD
                %  excessive temperature
                writeDigitalPin(a, greenPin, 0); % Turn off the green light.
                if yellowState == 1, writeDigitalPin(a, yellowPin, 0); yellowState = 0; end % Turn off the yellow light.

                % Handling red light blinking
                if toc(lastRedToggleTime) >= RED_BLINK_INTERVAL
                    redState = ~redState; % Toggle state
                    writeDigitalPin(a, redPin, redState);
                    lastRedToggleTime = tic; % reset timer
                end
            end

        catch readException
            disp(['Error reading or processing data. ', readException.message]);
            % In this case, consider not updating the LED or keeping the previous state
            pause(0.5); % Short pause to avoid rapid succession of errors
        end

        % 5. Control cycle rate
        elapsedLoopTime = toc(loopStartTime);
        pauseTime = LOOP_TARGET_TIME - elapsedLoopTime;
        if pauseTime > 0
            pause(pauseTime); % Pause the remaining time to reach the target cycle rate
        else
             disp('Warning: Loop execution time exceeds target time!'); % If the loop is too slow
        end
    end % finish while true
end

% Cleanup functions
function cleanupFunction(a, greenPin, yellowPin, redPin, fig)
    disp('Perform cleanup operations...');
    % Turn off all LEDs
    if exist('a','var') && isvalid(a)
        writeDigitalPin(a, greenPin, 0);
        writeDigitalPin(a, yellowPin, 0);
        writeDigitalPin(a, redPin, 0);
        disp('All LEDs are off.');
        
    end
    % Close the graphics window (if it exists and works)
    if exist('fig','var') && ishandle(fig)
        close(fig);
        disp('The graphics window is closed.');
    end
    disp('Clearance complete.');
end
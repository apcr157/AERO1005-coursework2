

function temp_prediction(a, analogPin, greenPinRate, yellowPinRate, redPinRate)
    %TEMP_PREDICTION Monitors the rate of temperature change, predicts future temperatures, and indicates rate stability with an LED.。
    %   temp_prediction(a, analogPin, greenPinRate, yellowPinRate, redPinRate)
    %   Continuously monitors the temperature, calculates the rate of change, predicts the temperature after 5 minutes, 
    %   and uses an LED to indicate whether the rate of change is more than +/- 4°C/min.Press Ctrl+C to stop.
    %
    %   Inputs:
    %       a             - Connected Arduino objects.
    %       analogPin     - Connect the analog pin of the temperature sensor ('A0')。
    %       greenPinRate  - Rate stabilization indication LED (green) ('D9').
    %       yellowPinRate - Falling Too Fast Indicator LED (yellow) ('D10').
    %       redPinRate    - Excessive rise indication LED (red) ('D11').
    %
    %   (Task 3e: Documentation)

    disp('Initialize the temperature predictor...');

    % Definition of constants 
    Tc = 0.010;             % V/°C
    Vo0C = 0.500;           % V at 0°C
    RATE_THRESHOLD_C_PER_MIN = 4.0; % °C/min
    RATE_THRESHOLD_C_PER_SEC = RATE_THRESHOLD_C_PER_MIN / 60.0; % °C/s
    PREDICTION_TIME_SEC = 5 * 60; % 5 minutes in seconds
    RATE_WINDOW_SIZE = 30;   % Number of data points used to calculate rate (30 seconds)
    MIN_DATA_FOR_RATE = 10; % What is the minimum number of points needed to start calculating the rate
    LOOP_TARGET_TIME = 1.0;  % sec

    % Initialize data buffer and plot (similar to Task 2)
    PLOT_BUFFER_SIZE = 300; % drawing buffer
    timeBuffer = NaN(1, PLOT_BUFFER_SIZE);
    tempBuffer = NaN(1, PLOT_BUFFER_SIZE);
    fig = figure;
    ax = axes(fig);
    plotHandle = plot(ax, timeBuffer, tempBuffer, '-b');
    xlabel(ax, 'Time (s)');
    ylabel(ax, 'Temperature (°C)');
    title(ax, 'Real-time temperature monitoring and forecasting');
    grid(ax, 'on');
    ylim(ax, [10 35]);
    startTime = tic;
    dataIndex = 0;

    % Initialize rate calculation related variables 
    rateOfChange_C_per_sec = 0; % Initialization rate of ch ange (°C/s)
    predictedTemp = NaN;      % Initialize the predicted temperature

    % Initialization rate LED
    writeDigitalPin(a, greenPinRate, 1); % Default rate stabilization
    writeDigitalPin(a, yellowPinRate, 0);
    writeDigitalPin(a, redPinRate, 0);
    disp('Rate LED initialization complete (green on).');

    % Setting up clean-up tasks
    cleanupObj = onCleanup(@() cleanupRateFunction(a, greenPinRate, yellowPinRate, redPinRate, fig));
    disp('Enter predictive monitoring loop (press Ctrl+C to stop)...');

    % Main monitoring loop
    while true
        loopStartTime = tic;

        try
            % 1. Temperature reading (can add multiple samples for averaging)
             numSamples = 3; % Reducing noise
             voltageSum = 0;
             for sample = 1:numSamples
                 voltageSum = voltageSum + readVoltage(a, analogPin);
                 pause(0.01);
             end
             voltage = voltageSum / numSamples;
             currentTemp = (voltage - Vo0C) / Tc;

            % 2. Record data (circular buffer)
            dataIndex = dataIndex + 1;
            bufferIndex = mod(dataIndex - 1, PLOT_BUFFER_SIZE) + 1;
            currentTime = toc(startTime);
            timeBuffer(bufferIndex) = currentTime;
            tempBuffer(bufferIndex) = currentTemp;

            % 3. Update mapping (similar to Task 2)
            validIndices = ~isnan(timeBuffer);
            plotTime = timeBuffer(validIndices);
            plotTemp = tempBuffer(validIndices);
            [plotTime, sortOrder] = sort(plotTime);
            plotTemp = plotTemp(sortOrder);
            set(plotHandle, 'XData', plotTime, 'YData', plotTemp);
            if currentTime > PLOT_BUFFER_SIZE * LOOP_TARGET_TIME * 0.5 % Dynamic adjustment of the X-axis
                set(ax, 'XLim', [max(0, currentTime - PLOT_BUFFER_SIZE*LOOP_TARGET_TIME), currentTime + LOOP_TARGET_TIME*10]);
            end
            drawnow limitrate;

            % 4. Calculate the rate of temperature change (using linear regression)
            if dataIndex >= MIN_DATA_FOR_RATE
                % Get the window data used to calculate the rate
                windowIndices = (max(1, dataIndex - RATE_WINDOW_SIZE + 1)):dataIndex;
                % Handling Circular Buffer Wrap
                actualIndices = mod(windowIndices - 1, PLOT_BUFFER_SIZE) + 1;

                timeWindow = timeBuffer(actualIndices);
                tempWindow = tempBuffer(actualIndices);

                % Remove NaN values from the window
                validWindow = ~isnan(timeWindow) & ~isnan(tempWindow);
                timeWindowValid = timeWindow(validWindow);
                tempWindowValid = tempWindow(validWindow);

                if numel(timeWindowValid) >= 2 % At least two points are needed to fit a straight line
                    try
                        coeffs = polyfit(timeWindowValid, tempWindowValid, 1); % linear fitting T = coeffs(1)*time + coeffs(2)
                        rateOfChange_C_per_sec = coeffs(1); % The slope is the rate of change °C/s
                    catch fitError
                        disp(['Linear Fit Error. ', fitError.message]);
                        rateOfChange_C_per_sec = 0; % Rate set to 0 on error
                    end
                else
                    rateOfChange_C_per_sec = 0; % Rate is set to 0 when there is not enough data
                end
            else
                 rateOfChange_C_per_sec = 0; % Insufficient data at the initial stage
            end

            % 5. Predicted temperature in 5 minutes
            predictedTemp = currentTemp + rateOfChange_C_per_sec * PREDICTION_TIME_SEC;

            % 6. Screen Output (Task 3c)
            rate_C_per_min = rateOfChange_C_per_sec * 60; % Converted to °C/min for display
            fprintf('Current: %.2f°C | Rate: %.2f°C/min | Forecast (after 5min): %.2f°C\n', ...
                    currentTemp, rate_C_per_min, predictedTemp);

            % 7. Control Rate LED (Task 3d)
            if rate_C_per_min > RATE_THRESHOLD_C_PER_MIN
                % Rising too fast
                writeDigitalPin(a, redPinRate, 1);
                writeDigitalPin(a, greenPinRate, 0);
                writeDigitalPin(a, yellowPinRate, 0);
            elseif rate_C_per_min < -RATE_THRESHOLD_C_PER_MIN
                % The decline is too rapid.
                writeDigitalPin(a, yellowPinRate, 1);
                writeDigitalPin(a, greenPinRate, 0);
                writeDigitalPin(a, redPinRate, 0);
            else
                % Rate stabilization
                writeDigitalPin(a, greenPinRate, 1);
                writeDigitalPin(a, yellowPinRate, 0);
                writeDigitalPin(a, redPinRate, 0);
            end

        catch readOrPlotException
            disp(['Error in loop. ', readOrPlotException.message]);
            pause(0.5);
        end

        % 8. Control cycle rate
        elapsedLoopTime = toc(loopStartTime);
        pauseTime = LOOP_TARGET_TIME - elapsedLoopTime;
        if pauseTime > 0
            pause(pauseTime);
        else
             % disp('Warning: Predicted loop execution time exceeds target!');
        end
    end % finish while true

end

% Cleanup functions
function cleanupRateFunction(a, greenPinRate, yellowPinRate, redPinRate, fig)
    disp('Perform predictor cleanup operations...');
    if exist('a','var') && isvalid(a)
        writeDigitalPin(a, greenPinRate, 0);
        writeDigitalPin(a, yellowPinRate, 0);
        writeDigitalPin(a, redPinRate, 0);
        disp('All rate LEDs are off。');
    end
    if exist('fig','var') && ishandle(fig)
        close(fig);
        disp('The graphics window is closed.');
    end
    disp('Predictor cleanup complete.');
end

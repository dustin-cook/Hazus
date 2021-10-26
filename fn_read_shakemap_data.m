function [ pga ] = fn_read_shakemap_data( lat, lng, shakemap_name )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%% Load Shakemap
shakemap_table = readtable(['shakemaps' filesep shakemap_name '_shakemap.csv']);

%% Iterpolate shaking intensity at site
% Check if lat/long is in bounds
if lat >= min(shakemap_table.LAT) && lat <= max(shakemap_table.LAT) && lng >= min(shakemap_table.LON) && lng <= max(shakemap_table.LON)
    % Find 4 interp points
    above_lat = min(shakemap_table.LAT(shakemap_table.LAT >= lat));
    below_lat = max(shakemap_table.LAT(shakemap_table.LAT <= lat));
    above_lng = min(shakemap_table.LON(shakemap_table.LON >= lng));
    below_lng = max(shakemap_table.LON(shakemap_table.LON <= lng));

    % define column filters for each of the 4 grid points
    pnt_1 = (shakemap_table.LAT == below_lat) & (shakemap_table.LON == below_lng);
    pnt_2 = (shakemap_table.LAT == above_lat) & (shakemap_table.LON == below_lng);
    pnt_3 = (shakemap_table.LAT == below_lat) & (shakemap_table.LON == above_lng);
    pnt_4 = (shakemap_table.LAT == above_lat) & (shakemap_table.LON == above_lng);
    
    % Find pga values associated with each point
    pga1 = log(shakemap_table.PGA(pnt_1)); % log based interpolation
    pga2 = log(shakemap_table.PGA(pnt_2));
    pga3 = log(shakemap_table.PGA(pnt_3));
    pga4 = log(shakemap_table.PGA(pnt_4));

    % Interpolate between points
    % interpolate to get z5 (make sure denominator != 0)
    if (above_lat - below_lat) == 0
        slope5 = 0;
        slope6 = 0;
    else
        slope5 = (pga2 - pga1) / (above_lat - below_lat);
        slope6 = (pga4 - pga3) / (above_lat - below_lat);
    end
    
    pga5 = pga1 + slope5 * (lat - below_lat);   
    pga6 = pga3 + slope6 * (lat - below_lat);

    % iterpolate between z5, z6
    if (above_lng - below_lng) == 0
        slope7 = 0;
    else
        slope7 = (pga6 - pga5) / (above_lng - below_lng);
    end
    
    pga7 = pga5 + slope7 * (lng - below_lng);
    pga = exp(pga7); % transform back into standard units
else
    % Outside of bounds, set shaking to zero
    pga = 0;
end
end


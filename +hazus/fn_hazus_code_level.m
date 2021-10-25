function [ code_level ] = fn_hazus_code_level( zone, building_type, year_of_construction )
% DESCRIPTION:
% Determines the hazus code level based upon the seismic zone, building type and year of construction. 
%
% Created by Katie Wade August 2017
% Modified by Dustin Cook August 2018

% INPUTS:
%   zone - P58 occpancy
%       seismicZone == '4'
%       seismicZone == '3'
%       seismicZone == '2A'
%       seismicZone == '1'
%       seismicZone == '0'
%   building_type - HAZUS building type string indentifier
%   year_of_construction - numerical year of construction
%
% OUTPUT:
%   code_level - Per HAZUS
%        1 --> High Code
%        2 --> Moderate Code
%        3 --> Low Code
%        4 --> Pre-Code

% OTHER SCRIPTS:

% ASSUMPTIONS:
% - building age is appropiately estimated by construction year
% - Table 5.2 (HAZUS) is used to translate the zone to the building code level

% NOTES: 

% TODO:

%% Begin Method
% check the building type for wood (changes how zone translates to code level)
if strcmp(building_type,'W1')
    is_wood=1;
else
    is_wood=0;
end

% Set seismic zone zero to one
if strcmp(zone,'0')
    zone = '1';
end

% Check to see if the UBC zone is just "2"
if strcmp(zone,'2')
    zone = '2A'; % Set zone to 2A (lower seismicity of the two)
end

% pull in the translation data
load(['+hazus' filesep 'data_hazus' filesep 'data_hazus_level_of_code.mat']);                   

% Filter table
filt_1 = hazus_level_of_code(hazus_level_of_code.is_wood==is_wood,:); % filter by wood
filt_2 = filt_1(strcmp(filt_1.ubc_seismic_zone,zone),:); % filter by seismic zone
filt_3 = filt_2(filt_2.year_adopted<=year_of_construction,:); % filter by year of construction 
code_level = filt_3.level_of_code{filt_3.year_adopted == max(filt_3.year_adopted)}; % choose the newest year that applies

end
clear all
close all
clc
rehash

%% Define Building and Site Inputs
% Site info
site = struct('lat', 39.0618, 'lng', -77.0536);  % LA

% Building
haz_building_class = 'C1';
hazus_zone = '4';
num_stories = 4;
year_of_construction = 2020;
hazus.occupancy = 'COM4';

%% Import Packages
import hazus.*

%% Pull Shakemap data for this site
[ pga ] = fn_read_shakemap_data( site.lat, site.lng, 'mineral_VA' );

%% Define transitionary Inputs
[ hazus.building_type ] = fn_hazus_building_type( haz_building_class, num_stories );
[ hazus.code_level ] = fn_hazus_code_level( hazus_zone, hazus.building_type, year_of_construction );

%% Run Hazus
[ loss ] = main_hazus_eq_pga( hazus.building_type.build_type, hazus.occupancy, hazus.code_level, pga );

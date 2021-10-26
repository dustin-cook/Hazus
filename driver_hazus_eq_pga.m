clear all
close all
clc
rehash

%% Define Building and Site Inputs
% Building
haz_building_class = 'C1';
hazus_zone = '4';
num_stories = 4;
year_of_construction = 2020;
hazus.occupancy = 'COM4';

% Hazard
pga = 0.8;

%% Import Packages
import hazus.*

%% Define transitionary Inputs
[ hazus.building_type ] = fn_hazus_building_type( haz_building_class, num_stories );
[ hazus.code_level ] = fn_hazus_code_level( hazus_zone, hazus.building_type, year_of_construction );

%% Run Hazus
[ loss ] = main_hazus_eq_pga( hazus.building_type.build_type, hazus.occupancy, hazus.code_level, pga );

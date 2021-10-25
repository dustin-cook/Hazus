clear all
close all
clc
rehash

%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here


%% Define Building and Site Inputs
% Site
data.site = struct('lat', 34.05, 'lng', -118.25);  % LA
% site.vs30 = [];

% Building
haz_building_class = 'C1';
hazus_zone = '4';
num_stories = 4;
year_of_construction = 2020;
hazus.occupancy = 'COM4';

% Hazard
spectra.periods = [0.1 0.2 0.3 0.4 0.5 1   1.5  2   3    5];
spectra.sa =      [0.5 1   1   0.8 0.7 0.5 0.45 0.4 0.37 0.35];

%% Import Packages
import hazus.*

%% Define transitionary Inputs
[ hazus.building_type ] = fn_hazus_building_type( haz_building_class, num_stories );
% [ hazus_zone ] = fn_UBC1997_get_mapped_seismic_zone(site.lat, site.lng);
[ hazus.code_level ] = fn_hazus_code_level( hazus_zone, hazus.building_type, year_of_construction );
% [ hazus.occupancy ] = fn_hazus_occupancy( occupancy_id, haz_building_class );
% hazus.class = [hazus.building_type.build_type{1} '-' hazus.code_level];

%% Run Hazus
[ loss ] = main_hazus( hazus.building_type.build_type, hazus.occupancy, hazus.code_level, spectra, [] );

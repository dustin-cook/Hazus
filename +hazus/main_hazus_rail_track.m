function [ loss ] = main_hazus_rail_track( lifeline_type, lifeline_class, pgd )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%% Hazus Notes
% The reference spectrum represents ground
% shaking of a large-magnitude (i.e., M ? 7.0) western United States (WUS) earthquake for soil
% sites (e.g., Site Class D) at site-to-source distances of 15 km, or greater
% uncertainty in the damage?state threshold of the structural system Beta_M(SPGA) = 0.4 for all building types and damage states),
% variability in response due to the spatial variability of ground motion demand B_D(V) = 0.5 for long?period spectral response).

%% Initial Setup
% Import packages
import hazus.fn_calc_hazus_loss

% Load data
fragility_table = readtable(['+hazus' filesep 'data_hazus' filesep 'hazus_rail_fragility.csv']);
consequence_table = readtable(['+hazus' filesep 'data_hazus' filesep 'hazus_rail_consequence.csv']);

%% Define Building Fragility
filt = strcmp(fragility_table.lifeline_class,lifeline_class);
fragility_data = fragility_table(filt,:);

%% Define Consequence
consequence_data = consequence_table(strcmp(consequence_table.lifeline_type,lifeline_type),:);

%% Define Building Loss
[ loss ] = fn_calc_hazus_loss( fragility_data, consequence_data, pgd, 'mean_recovery_days' );

end


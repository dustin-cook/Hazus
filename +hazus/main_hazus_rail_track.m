function [ loss ] = main_hazus_rail_track( pgd )
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
import hazus.fn_hazus_ds
import hazus.fn_hazus_loss

% Load data
fragility_table = readtable(['+hazus' filesep 'data_hazus' filesep 'hazus_rail_fragility.csv']);
consequence_table = readtable(['+hazus' filesep 'data_hazus' filesep 'hazus_rail_consequence.csv']);

% Filter data
filt = strcmp(fragility_table.lifeline_class,'RTR1');
fragility_data = fragility_table(filt,:);
consequence_data = consequence_table(strcmp(consequence_table.lifeline_type,'RTR'),:);

%% Define Loss
[ prob_ds ] = fn_hazus_ds( fragility_data, pgd );
[ loss ] = fn_hazus_loss( prob_ds, consequence_data, 'mean_recovery_days' );

end


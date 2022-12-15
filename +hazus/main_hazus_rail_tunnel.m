function [ loss ] = main_hazus_rail_tunnel( pga, pgd )
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
import hazus.sim_hazus_ds
import hazus.fn_hazus_loss

% Load data
consequence_table = readtable(['+hazus' filesep 'data_hazus' filesep 'hazus_rail_consequence.csv']);
fragility_table = readtable(['+hazus' filesep 'data_hazus' filesep 'hazus_rail_fragility.csv']);

% Filter databases
fragility_data = fragility_table(strcmp(fragility_table.lifeline_class,'RTU2'),:); % Assume cut and covered tunnels
consequence_data = consequence_table(strcmp(consequence_table.lifeline_type,'RTU'),:);

%% Calculate Building Damage
n_sims = 10000;

% Loss from ground shaking
fragility_data_pga = fragility_data(strcmp(fragility_data.intensity_measure,'pga'),:);
[ ds_pga ] = sim_hazus_ds( fragility_data_pga, pga, n_sims );

% Loss from ground failre
fragility_data_pgd = fragility_data(strcmp(fragility_data.intensity_measure,'pgd'),:);
[ ds_pgd ] = sim_hazus_ds( fragility_data_pgd, pgd, n_sims );

% Combine damage state probailities using total probability theorem
ds_sim_total = ds_pga | ds_pgd;
prob_ds_exceed = mean(ds_sim_total);

% damage state probabilities
prob_ds = prob_ds_exceed - [prob_ds_exceed(2:end),0];

%% Calculate Building Loss
[ loss ] = fn_hazus_loss( prob_ds, consequence_data, 'mean_recovery_days' );

end


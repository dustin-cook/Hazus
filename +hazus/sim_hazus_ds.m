function [ ds_sim ] = sim_hazus_ds( damage_curves, shaking_intensity, n_sims )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%% Find Damage State Probabilities
% Assemble Median and Beta Vectors
ds_medians = [damage_curves.median(strcmp(damage_curves.damage_state,'slight')),...
              damage_curves.median(strcmp(damage_curves.damage_state,'moderate')),...
              damage_curves.median(strcmp(damage_curves.damage_state,'extensive')),...
              damage_curves.median(strcmp(damage_curves.damage_state,'complete'))];

ds_betas = [damage_curves.beta(strcmp(damage_curves.damage_state,'slight')),...
            damage_curves.beta(strcmp(damage_curves.damage_state,'moderate')),...
            damage_curves.beta(strcmp(damage_curves.damage_state,'extensive')),...
            damage_curves.beta(strcmp(damage_curves.damage_state,'complete'))];

% damage state exceedance probabilities per pgaVals 
prob_ds_exceed = normcdf( log(shaking_intensity./ds_medians)./ds_betas);
p = rand(n_sims, 1);
ds_sim = p <= prob_ds_exceed;


end


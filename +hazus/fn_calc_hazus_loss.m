function [ loss ] = fn_calc_hazus_loss( damage_curves, consequence_data, shaking_intensity, target )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%% Find Damage State Probabilities
% Assemble Median and Beta Vectors
ds_medians = [damage_curves.median_slight, damage_curves.median_moderate, damage_curves.median_extensive, damage_curves.median_complete];
ds_betas = [damage_curves.beta_slight, damage_curves.beta_moderate, damage_curves.beta_extensive, damage_curves.beta_complete];

% damage state exceedance probabilities per pgaVals 
prob_ds_exceed = normcdf( log(shaking_intensity./ds_medians)./ds_betas);

% damage state probabilities
prob_ds = prob_ds_exceed - [prob_ds_exceed(2:end),0];

%% Compute Loss
% Find loss ratios for the given occupancy type
loss_values = [consequence_data.(target)(strcmp(consequence_data.damage_state,'slight')),...
               consequence_data.(target)(strcmp(consequence_data.damage_state,'moderate')),...
               consequence_data.(target)(strcmp(consequence_data.damage_state,'extensive')),...
               consequence_data.(target)(strcmp(consequence_data.damage_state,'complete'))];

% compute loss ratios per PGA
loss = sum(prob_ds .* loss_values);

end


function [ loss ] = fn_calc_hazus_loss( damage_curves, hazus_cost_ds, spectral_value, type )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%% Find Damage State Probabilities
% Assemble Median and Beta Vectors
ds_medians = [damage_curves.median_slight, damage_curves.median_moderate, damage_curves.median_extensive, damage_curves.median_complete];
ds_betas = [damage_curves.beta_slight, damage_curves.beta_moderate, damage_curves.beta_extensive, damage_curves.beta_complete];

% damage state exceedance probabilities per pgaVals 
prob_ds_exceed = [normcdf( log(spectral_value./ds_medians)./ds_betas),0]; % pad with zeros for probability of exceeding DS 5, to help with differentiation in the next step

% damage state probabilities
for j = 1:4
    prob_ds(:,j) = prob_ds_exceed(:,j) - prob_ds_exceed(:,j+1);
end

%% Compute Loss
% Find loss ratios for the given occupancy type
loss_values = [hazus_cost_ds.([type '_slight']), hazus_cost_ds.([type '_moderate']), hazus_cost_ds.([type '_extensive']), hazus_cost_ds.([type '_complete'])];

% compute loss ratios per PGA
loss = (sum(prob_ds .* loss_values)/100)';

end


function [ loss ] = fn_hazus_loss( prob_ds, consequence_data, target )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here


%% Compute Loss
% Find loss ratios for the given occupancy type
loss_values = [consequence_data.(target)(strcmp(consequence_data.damage_state,'slight')),...
               consequence_data.(target)(strcmp(consequence_data.damage_state,'moderate')),...
               consequence_data.(target)(strcmp(consequence_data.damage_state,'extensive')),...
               consequence_data.(target)(strcmp(consequence_data.damage_state,'complete'))];

% compute loss ratios per PGA
loss = sum(prob_ds .* loss_values);

end


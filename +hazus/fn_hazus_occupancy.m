function [ occ_hazus_select ] = fn_hazus_occupancy( occupancy_id, build_type )
% DESCRIPTION:
% Take the P58 occupancy and find the most applicable HAZUS occupancy
%
% Created by Katie Wade August 2017
% Updated by Dustin Cook 7-13-18
%
% INPUTS:
%   Numerical Occupancy ID
%   building type (string ID)
%
% OUTPUT:
%   Single Hazus Occupancy String
%
% OTHER SCRIPTS:
%
% ASSUMPTIONS
%
% NOTES: 
%
% TODO:
%
%% Start Method
% Load P-58 Occupancy Table
load(['..' filesep 'SPEX' filesep '+hbr' filesep '+spex' filesep '+building_setup' filesep 'data_build_type' filesep 'data_occupancy.mat']);

% Filter table to find Hazus Occupancy Based on P-58 Occupancy
occ_hazus_raw=occupancy.hazus_label{occupancy.id == occupancy_id};
occ_hazus_all = strsplit(occ_hazus_raw,',');

% If There is more than one hazus occupancy, then select most apporpriate
% based on building type
if length(occ_hazus_all) > 1
    if strcmp(build_type,'PC1a') || strcmp(build_type,'RM1a')
        occ_hazus_select = occ_hazus_all{2}; % Pick wholesale retail or light industurial for tiltup
    else
        occ_hazus_select = occ_hazus_all{1}; % Pick the first occupancy if multiple
    end
else
    occ_hazus_select = occ_hazus_all{1};
end

end

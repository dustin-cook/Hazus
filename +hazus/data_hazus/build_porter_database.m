% Script to take Dr. Porter's raw hazus dataset and convert feild to bve
% compatible with the benchmarking methods
clear all 
close all
clc

% Load Dr Porter Hazus Loss Database
porter_loss_table = readtable('2014_05_16_VUL06.csv','ReadVariableNames',true);

% Change Generic Residential Occupancy to Residential 3
porter_loss_table.OCC(strcmp(porter_loss_table.OCC,'RES3AF')) = {'RES3'};

% Change representation of level of Design attribute (aka Level of Code)
porter_loss_table.Design(strcmp(porter_loss_table.Design,'h')) = {'high'};
porter_loss_table.Design(strcmp(porter_loss_table.Design,'m')) = {'moderate'};
porter_loss_table.Design(strcmp(porter_loss_table.Design,'l')) = {'low'};
porter_loss_table.Design(strcmp(porter_loss_table.Design,'p')) = {'pre'};

% Save new database
save('porter_loss_table.mat','porter_loss_table')
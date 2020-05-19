%% display_region_stat_fig.m
%
% Display figure with table summarizing region stats.
%
%% Help
%
% *USE*
%
% TODO
%
% *INPUT VARIABLES*
%
% * |main_figure|: Handle to main ESP3 window
% * |regIntStruct|: Output from integrate_region
%
% *OUTPUT VARIABLES*
%
% * |hfig|: Handle to created figure
%
% *RESEARCH NOTES*
%
% TODO
%
% *NEW FEATURES*
%
% * 2017-03-22: header and comments updated according to new format (Alex Schimel)
% * 2017-03-07: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function hfig = display_region_stat_fig(main_figure,regIntStruct)


hfig=new_echo_figure(main_figure,'Tag','reg_stat','Resize','off','Units','pixels','Position',[200 200 400 400]);

columnname = {'Variable','Value','unit'};
columnformat = {'char','numeric','char'};
regSummary=cell(6,3);

Sa_lin=(nansum(nansum(regIntStruct.eint))./nansum(nanmax(regIntStruct.Nb_good_pings)));

regSummary{1,1}='Sv Mean';
regSummary{1,2}=pow2db_perso(nanmean(regIntStruct.sv_mean(:)));
regSummary{1,3}='dB';

regSummary{2,1}='Sa';
regSummary{2,2}=pow2db_perso(Sa_lin);
regSummary{2,3}='dB';

regSummary{3,1}='Number of Samples';
regSummary{3,2}=nanmean(nansum(regIntStruct.nb_samples));
regSummary{3,3}='';

regSummary{4,1}='NASC';
regSummary{4,2}=nanmean(nansum(regIntStruct.NASC));
regSummary{4,3}='m2/nmi2';

regSummary{5,1}='ABC';
regSummary{5,2}=nanmean(nansum(regIntStruct.ABC));
%   regSummary{5,2}= nansum(nansum(regIntStruct.eint))./nansum(nanmax(regIntStruct.Nb_good_pings));
regSummary{5,3}='m2/m2';

regSummary{6,1}='Region Length';
regSummary{6,2}=nanmax(regIntStruct.Dist_E(:))-nanmin(regIntStruct.Dist_S(:));
regSummary{6,3}='m';

regSummary{7,1}='Region Height';
regSummary{7,2}=nanmax(regIntStruct.Depth_max(:))-nanmin(regIntStruct.Depth_min(:));
regSummary{7,3}='m';

regSummary{8,1}='Nb Cells';
regSummary{8,2}=nansum(regIntStruct.sv_mean(:)>0);
regSummary{8,3}='';


table_main=uitable('Parent',hfig,...
    'Data', regSummary,...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'ColumnEditable', [false false false],...
    'Units','Normalized','Position',[0 0 1 1],...
    'RowName',[]);

pos_t = getpixelposition(table_main);

set(table_main,'ColumnWidth',{pos_t(3)/3, pos_t(3)/3, pos_t(3)/3});


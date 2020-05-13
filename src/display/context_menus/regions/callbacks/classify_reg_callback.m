%% classify_reg_callback.m
%
% TODO: write short description of function
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |reg_curr|: TODO: write description and info on variable
% * |main_figure|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-03-28: header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function classify_reg_callback(~,~,main_figure)

layer=get_current_layer();
curr_disp=get_esp3_prop('curr_disp');
load_bar_comp=getappdata(main_figure,'Loading_bar');
hfigs=getappdata(main_figure,'ExternalFigures');

[trans_obj,~]=layer.get_trans(curr_disp);

reg_obj=trans_obj.get_region_from_Unique_ID(curr_disp.Active_reg_ID);
if isempty(reg_obj)
    return;
end
update_algos(main_figure,'algo_name',{'Classification'});
update_survey_opts(main_figure);
show_status_bar(main_figure);
survey_opt_obj=layer.get_survey_options();
survey_opt_obj.Frequency=curr_disp.Freq;
survey_opt_obj.Denoised=true;

layer.apply_algo('Classification','load_bar_comp',load_bar_comp,...
    'survey_options',survey_opt_obj,...
    'reg_obj',reg_obj);

setappdata(main_figure,'ExternalFigures',hfigs);

update_echo_int_tab(main_figure,0);
update_reglist_tab(main_figure,1);
display_regions(main_figure,'both');
order_stacks_fig(main_figure,curr_disp);
hide_status_bar(main_figure);
end

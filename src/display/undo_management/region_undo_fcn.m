%% region_undo_fcn.m
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
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-09-12 first version (Yoann Ladroit). TODO: complete date and comment
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function region_undo_fcn(main_figure,trans_obj,regs)
if~isdeployed()
    disp_perso(main_figure,'Undo Region')
end
trans_obj.rm_all_region();
IDs=trans_obj.add_region(regs);
curr_disp=get_esp3_prop('curr_disp');
display_regions('all');
curr_disp.Reg_changed_flag=1;
if ~isempty(IDs)
    curr_disp.setActive_reg_ID({});   
    curr_disp.Reg_changed_flag=1;
end
end



%% load_track_target_tab.m
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
% * |main_figure|: TODO: write description and info on variable
% * |algo_tab_panel|: TODO: write description and info on variable
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
function load_track_target_tab(main_figure,algo_tab_panel)


track_target_tab=uitab(algo_tab_panel,'Title','Target Tracking');

gui_fmt=init_gui_fmt_struct();

pos=create_pos_3(7,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);

next_w=[gui_fmt.x_sep+gui_fmt.box_w 0 0 0];

alpha_beta=uipanel(track_target_tab,'title','Step 1: Alpha/Beta tracking','Position',[0.0 0.0 0.3 1],'Tag','alpha_beta');

uicontrol(alpha_beta,gui_fmt.txtStyle,'string','Al.','pos',pos{1,1}{2},'HorizontalAlignment','left','tooltipstring','AlongShip');
uicontrol(alpha_beta,gui_fmt.txtStyle,'string','Ac.','pos',pos{1,1}{2}+next_w,'HorizontalAlignment','left','tooltipstring','AcrossShip');
uicontrol(alpha_beta,gui_fmt.txtStyle,'string','R.','pos',pos{1,1}{2}+2*next_w,'HorizontalAlignment','left','tooltipstring','Range');
uicontrol(alpha_beta,gui_fmt.txtStyle,'string','Alpha','pos',pos{2,1}{1});

track_target_tab_comp.AlphaMinAxis=uicontrol(alpha_beta,gui_fmt.edtStyle,'pos',pos{2,1}{2});
track_target_tab_comp.AlphaMajAxis=uicontrol(alpha_beta,gui_fmt.edtStyle,'pos',pos{2,1}{2}+next_w);
track_target_tab_comp.AlphaRange=uicontrol(alpha_beta,gui_fmt.edtStyle,'pos',pos{2,1}{2}+2*next_w);

uicontrol(alpha_beta,gui_fmt.txtStyle,'string','Beta','pos',pos{3,1}{1});
track_target_tab_comp.BetaMinAxis=uicontrol(alpha_beta,gui_fmt.edtStyle,'pos',pos{3,1}{2});
track_target_tab_comp.BetaMajAxis=uicontrol(alpha_beta,gui_fmt.edtStyle,'pos',pos{3,1}{2}+next_w);
track_target_tab_comp.BetaRange=uicontrol(alpha_beta,gui_fmt.edtStyle,'pos',pos{3,1}{2}+2*next_w);

uicontrol(alpha_beta,gui_fmt.txtStyle,'string','Excl dist(m)','pos',pos{4,1}{1});
track_target_tab_comp.ExcluDistMinAxis=uicontrol(alpha_beta,gui_fmt.edtStyle,'pos',pos{4,1}{2});
track_target_tab_comp.ExcluDistMajAxis=uicontrol(alpha_beta,gui_fmt.edtStyle,'pos',pos{4,1}{2}+next_w);
track_target_tab_comp.ExcluDistRange=uicontrol(alpha_beta,gui_fmt.edtStyle,'pos',pos{4,1}{2}+2*next_w);

uicontrol(alpha_beta,gui_fmt.txtStyle,'string',['Angle Uncert.(' char(hex2dec('00B0')) ')'],'pos',pos{5,1}{1});
track_target_tab_comp.MaxStdMinAxisAngle=uicontrol(alpha_beta,gui_fmt.edtStyle,'pos',pos{5,1}{2});
track_target_tab_comp.MaxStdMajAxisAngle=uicontrol(alpha_beta,gui_fmt.edtStyle,'pos',pos{5,1}{2}+next_w);

uicontrol(alpha_beta,gui_fmt.txtStyle,'string','Ping exp(%)','pos',pos{6,1}{1});
track_target_tab_comp.MissedPingExpMinAxis=uicontrol(alpha_beta,gui_fmt.edtStyle,'pos',pos{6,1}{2});
track_target_tab_comp.MissedPingExpMajAxis=uicontrol(alpha_beta,gui_fmt.edtStyle,'pos',pos{6,1}{2}+next_w);
track_target_tab_comp.MissedPingExpRange=uicontrol(alpha_beta,gui_fmt.edtStyle,'pos',pos{6,1}{2}+2*next_w);


weights_panel=uipanel(track_target_tab,'Position',[0.3 0 0.7 1]);

algo_name='TrackTarget';

load_algo_panel('main_figure',main_figure,...
        'panel_h',weights_panel,...
        'algo_name',algo_name,...
        'input_struct_h',track_target_tab_comp,...
        'title','Step 2: Weights & track acceptance',...
        'save_fcn_bool',true);

end


    

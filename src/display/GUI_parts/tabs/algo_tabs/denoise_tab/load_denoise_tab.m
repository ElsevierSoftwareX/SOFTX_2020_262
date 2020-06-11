%% load_denoise_tab.m
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
function load_denoise_tab(main_figure,algo_tab_panel)

denoise_tab=uitab(algo_tab_panel,'Title','Filtering');

algo_name='Denoise';

load_algo_panel('main_figure',main_figure,...
        'panel_h',uipanel(denoise_tab,'Position',[0 0 0.3 1]),...
        'algo_name',algo_name,...
        'title','Denoise',...
        'save_fcn_bool',true);
    
    
    gui_fmt=init_gui_fmt_struct();
    gui_fmt.txt_w=gui_fmt.txt_w*1.5;
    
    pos=create_pos_3(5,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);
    
    p_button=pos{5,1}{1};
    p_button(3)=gui_fmt.button_w;
    
    
    denoise_tab_comp.filtering_panel=uipanel(denoise_tab,'title','Notch Filtering (FM)','Position',[0.3 0 0.7 1]);
    
    denoise_tab_comp.table_notch_filter = uitable('Parent',denoise_tab_comp.filtering_panel,...
        'Data', [],...
        'ColumnName', {'F_min(kHz)' 'F_max(kHz)'},...
    'ColumnFormat', {'numeric' 'numeric'},...   
    'CellSelectionCallback',@cell_select_cback,... 
    'ColumnEditable', [true true],...  
    'CellEditCallBack',{@edit_band_stop_cback,main_figure},...
    'Units','Normalized','OuterPosition',[0.05 0.2 0.3 0.8],...
    'RowName',[]);

denoise_tab_comp.table_notch_filter.UserData.select=[];
set(denoise_tab_comp.table_notch_filter,'ColumnWidth','auto');
set_auto_resize_table(denoise_tab_comp.table_notch_filter);

rc_menu = uicontextmenu(ancestor(denoise_tab_comp.table_notch_filter,'figure'));
uimenu(rc_menu,'Label','Add notch','Callback',{@add_band_cback,denoise_tab_comp.table_notch_filter});
uimenu(rc_menu,'Label','Remove notch(es)','Callback',{@rm_bands_cback,denoise_tab_comp.table_notch_filter,main_figure});
denoise_tab_comp.table_notch_filter.UIContextMenu =rc_menu;

denoise_tab_comp.axe_filt = axes(denoise_tab_comp.filtering_panel,...
     'Units','Normalized','OuterPosition',[0.35 0.2 0.6 0.8],...
     'Box','on','nextplot','add',...
     'XGrid','on','YGrid','on','YLim',[-0.5 1.5],'YTick',[0 1]...
     );
  denoise_tab_comp.axe_filt.XAxis.TickLabelFormat  = '%d\kHz';
  
 denoise_tab_comp.applied_plot=plot(denoise_tab_comp.axe_filt,nan,nan,'-b');
 denoise_tab_comp.new_plot=plot(denoise_tab_comp.axe_filt,nan,nan,'--r');


uicontrol(denoise_tab_comp.filtering_panel,gui_fmt.pushbtnStyle,'String','Apply','pos',p_button+[1*gui_fmt.button_w 0 0 0],'callback',{@apply_notch_filtering,main_figure,1});
uicontrol(denoise_tab_comp.filtering_panel,gui_fmt.pushbtnStyle,'String','Reset','pos',p_button+[2*gui_fmt.button_w 0 0 0],'callback',{@apply_notch_filtering,main_figure,0});

setappdata(main_figure,'Denoise_tab',denoise_tab_comp);

end

function add_band_cback(src,evt,tb)
switch tb.Enable
    case 'on'
        tb.Data=[tb.Data;[0 0]];
end
end

function rm_bands_cback(src,evt,tb,main_figure)
if ~isempty(tb.Data)&&~isempty(tb.UserData.select)
    tb.Data(tb.UserData.select(:,1),:)=[];
    tb.UserData.select=[];
end
edit_band_stop_cback([],[],main_figure)
end

function edit_band_stop_cback(src,evt,main_figure)
layer=get_current_layer();
denoise_tab_comp=getappdata(main_figure,'Denoise_tab');

bandstops=denoise_tab_comp.table_notch_filter.Data*1e3;

 flim=layer.get_flim();
f_vec=flim(1):1e2:flim(end);
[h,w]=get_notch_filter(bandstops,f_vec);

set(denoise_tab_comp.new_plot,'XData',w/1e3,'YData',h);

end

function cell_select_cback(src,evt)
    src.UserData.select=evt.Indices;
end

function apply_notch_filtering(src,evt,main_figure,act)

curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();
denoise_tab_comp=getappdata(main_figure,'Denoise_tab');
load_bar_comp=getappdata(main_figure,'Loading_bar');
show_status_bar(main_figure);
if act>0
     layer.setNotchFilter(denoise_tab_comp.table_notch_filter.Data*1e3,load_bar_comp);
else
    layer.setNotchFilter([],load_bar_comp);   
end
update_denoise_tab(main_figure)

hide_status_bar(main_figure);

curr_disp.setField(curr_disp.Fieldname);

disp('Done');
end


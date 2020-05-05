
function load_echo_int_tab(main_figure,parent_tab_group)
% import javax.swing.*
% import java.awt.*

switch parent_tab_group.Type
    case 'uitabgroup'
        echo_int_tab_comp.echo_int_tab=new_echo_tab(main_figure,parent_tab_group,'Title','Echo Integration','UiContextMenuName','echoint_tab');
        pos_tab=getpixelposition(echo_int_tab_comp.echo_int_tab);
        pos_tab(4)=pos_tab(4);
    case 'figure'
        echo_int_tab_comp.echo_int_tab=parent_tab_group;
        pos_tab=getpixelposition(echo_int_tab_comp.echo_int_tab);
end
%drawnow;
curr_disp=get_esp3_prop('curr_disp');
layer_obj=get_current_layer();

opt_panel_size=[0 pos_tab(4)-500+1 300 500];
ax_panel_size=[opt_panel_size(3) 0 pos_tab(3)-opt_panel_size(3) pos_tab(4)];

echo_int_tab_comp.opt_panel=uipanel(echo_int_tab_comp.echo_int_tab,'units','pixels','BackgroundColor','white','position',opt_panel_size);
echo_int_tab_comp.ax_panel=uipanel(echo_int_tab_comp.echo_int_tab,'units','pixels','BackgroundColor','white','position',ax_panel_size);

[cmap, col_ax, col_lab, col_grid, col_bot, col_txt,~]=init_cmap(curr_disp.Cmap);
echo_int_tab_comp.main_ax=axes('Parent',echo_int_tab_comp.ax_panel,'Interactions',[],'Toolbar',[],...
    'Units','Normalized','position',[0.05 0 0.9 0.9],'Color',col_ax,'Layer','top','YTickLabel',{},'XTickLabel',{},'visible','on');
echo_int_tab_comp.v_ax=axes('Parent',echo_int_tab_comp.ax_panel,'Interactions',[],'Toolbar',[],...
    'Units','Normalized','position',[0 0 0.05 0.9],'YAxisLocation','right','XTickLabel',{},'visible','on');
echo_int_tab_comp.h_ax=axes('Parent',echo_int_tab_comp.ax_panel,'Interactions',[],'Toolbar',[],...
'Units','Normalized','position',[0.05 .9 0.9 0.1],'YTickLabel',{},'visible','on');
% echo_int_tab_comp.v_ax.YAxis.TickLabelFormat=' %.0g m';
echo_int_tab_comp.h_ax.XTickLabelRotation=-90;

colormap(echo_int_tab_comp.main_ax,cmap);

set([echo_int_tab_comp.h_ax,echo_int_tab_comp.v_ax,echo_int_tab_comp.main_ax],...
    'nextplot','add',...
    'box','on',...
    'XGrid','on',...
    'YGrid','on',...
    'GridLineStyle','--',...
    'GridColor',col_grid,'FontWeight','bold');
echo_int_tab_comp.cbar=colorbar(echo_int_tab_comp.main_ax,'Position',[0.95 0.05 0.02 0.8],'PickableParts','none');
echo_int_tab_comp.cbar.UIContextMenu=[];

linkaxes([echo_int_tab_comp.main_ax echo_int_tab_comp.v_ax],'y');
linkaxes([echo_int_tab_comp.main_ax echo_int_tab_comp.h_ax],'x');

rm_axes_interactions([echo_int_tab_comp.main_ax echo_int_tab_comp.v_ax echo_int_tab_comp.h_ax]);

echo_int=zeros(2,2);
echo_int_tab_comp.main_plot=pcolor(echo_int_tab_comp.main_ax,echo_int);
echo_int_tab_comp.v_plot=plot(echo_int_tab_comp.v_ax,[0 0],[0 0]);
echo_int_tab_comp.h_plot=plot(echo_int_tab_comp.h_ax,[0 0],[0 0]);
set(echo_int_tab_comp.main_plot,'facealpha','flat','edgecolor','none','AlphaDataMapping','none');
echo_int_tab_comp.main_plot.AlphaData=zeros(size(echo_int));

create_context_menu_int_plot(echo_int_tab_comp.main_plot);

        % cax=curr_disp.getCaxField('sv');
% caxis(echo_int_tab_comp.main_ax,cax);

%%%%%%Option Panel on the left side%%%%
%integration parameters
nb_rows=20;
gui_fmt=init_gui_fmt_struct();
gui_fmt.txt_w=gui_fmt.txt_w*0.8;
pos=create_pos_3(nb_rows,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtTitleStyle,'String','Parameters','Position',pos{1,1}{1}+[0 0 gui_fmt.txt_w 0]);

uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Main Chan.','Position',pos{2,1}{1});
echo_int_tab_comp.tog_freq=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.popumenuStyle,'String','--','Value',1,'Position',pos{2,1}{2}+[0 0 gui_fmt.box_w 0]);
curr_disp=init_grid_val(main_figure);
[dx,dy]=curr_disp.get_dx_dy();
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Cell Width','Position',pos{3,1}{1});
echo_int_tab_comp.cell_w=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{3,1}{2},'string',dx,'Tag','w');

uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Cell Height','Position',pos{4,1}{1});
echo_int_tab_comp.cell_h=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{4,1}{2},'string',dy,'Tag','h');

% if isempty(layer_obj.GPSData.Lat)
%     units_w= {'pings','seconds'};
%     xaxis_opt={'Ping Number' 'Time'};
% else
units_w= {'meters','pings','seconds'};
xaxis_opt={'Distance' 'Ping Number' 'Time' 'Lat' 'Long'};
%end

w_unit_idx=find(strcmp(curr_disp.Xaxes_current,units_w));

echo_int_tab_comp.cell_w_unit=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.popumenuStyle,'String',units_w,'Value',w_unit_idx,'Position',pos{3,2}{1},'Tag','w');
echo_int_tab_comp.cell_h_unit=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','meters','Position',pos{4,2}{1});

echo_int_tab_comp.cell_w_unit_curr=get(echo_int_tab_comp.cell_w_unit,'value');

uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Depth min(m)','Position',pos{5,1}{1});
echo_int_tab_comp.d_min=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{5,1}{2},'string',0,'Tag','rmin','callback',{@check_fmt_box,0,Inf,0,'%.1f'});

uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Depth max(m)','Position',pos{5,2}{1});
echo_int_tab_comp.d_max=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{5,2}{2},'string',Inf,'Tag','rmax','callback',{@check_fmt_box,0,Inf,Inf,'%.1f'});

echo_int_tab_comp.sv_thr_bool=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.chckboxStyle,'String','Sv Thr(dB)','Position',pos{6,1}{1},'Value',0);
echo_int_tab_comp.sv_thr=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{6,1}{2},'string',-999,'Tag','sv_thr','callback',{@check_fmt_box,-999,0,-80,'%.0f'});

set([echo_int_tab_comp.cell_w echo_int_tab_comp.cell_h],'callback',{@check_cell,main_figure,echo_int_tab_comp})
set(echo_int_tab_comp.cell_w_unit ,'callback',{@tog_units,main_figure,echo_int_tab_comp});


gui_fmt=init_gui_fmt_struct();
gui_fmt.txt_w=gui_fmt.txt_w*1.4;
pos=create_pos_3(nb_rows,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.txt_w,gui_fmt.box_h);

echo_int_tab_comp.denoised=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.chckboxStyle,'Value',0,'String','Denoised data','Position',pos{7,1}{1});
echo_int_tab_comp.motion_corr=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.chckboxStyle,'Value',0,'String','Motion Correction','Position',pos{7,1}{2});
echo_int_tab_comp.shadow_zone=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.chckboxStyle,'Value',0,'String','Shadow zone Est. (m)','Position',pos{7,1}{1},'visible','off');
echo_int_tab_comp.shadow_zone_h=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{7,1}{2}+[0 0 gui_fmt.box_w-gui_fmt.txt_w 0],'string','10','callback',{@ check_fmt_box,0,inf,10,'%.1f'},'visible','off');
echo_int_tab_comp.rm_st=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.chckboxStyle,'Value',0,'String','Rm.Single Targets','Position',pos{8,1}{1});
echo_int_tab_comp.all_freq=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.chckboxStyle,'Value',0,'String','All Frequencies','Position',pos{8,1}{2});

echo_int_tab_comp.reg_only=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.chckboxStyle,'Value',1,'String','Integrate by','Position',pos{9,1}{1},'Tooltipstring','unchecked: integrate all WC within bounds');
int_opt={'Tag' 'ID' 'Name' 'All Data Regions'};
echo_int_tab_comp.tog_int=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.popumenuStyle,'String',int_opt,'Value',1,'Position',pos{9,1}{2}-[0 0 gui_fmt.txt_w/3 0]);
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'position',pos{10,1}{1},'string','Region specs: ');
echo_int_tab_comp.reg_id_box=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.edtStyle,'position',pos{10,1}{2}-[0 0 gui_fmt.txt_w/3 0],'string','');

p_button=pos{11,1}{1};
p_button(3)=gui_fmt.button_w;
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.pushbtnStyle,'String','Compute','pos',p_button,'callback',{@slice_transect_cback,main_figure})
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.pushbtnStyle,'String','Export','pos',p_button+[gui_fmt.button_w 0 0 0],'callback',{@export_cback,main_figure})

set(echo_int_tab_comp.echo_int_tab,'ResizeFcn',{@resize_echo_int_cback,main_figure});

%display part
init_disp=13;
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtTitleStyle,'String','Display','Position',pos{init_disp,1}{1});
ref={'Surface','Bottom' 'Transducer'};
ref_idx=find(strcmp(ref,'Surface'));
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Reference ','Position',pos{init_disp+1,1}{1}-[0 0 gui_fmt.txt_w/2 0]);
echo_int_tab_comp.tog_ref=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.popumenuStyle,'String',ref,'Value',ref_idx,'Position',pos{init_disp+1,1}{1}+[gui_fmt.txt_w/2 0 -gui_fmt.txt_w/2 0],'callback',{@update_cback,main_figure});
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','Data ','Position',pos{init_disp+2,1}{1}-[0 0 gui_fmt.txt_w/2 0]);
echo_int_tab_comp.tog_type=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.popumenuStyle,'String',{'Sv' 'PRC' 'Std Sv' 'Nb Samples' 'Nb Tracks' 'Nb Single Targets' 'Tag'},'Value',1,'Position',pos{init_disp+2,1}{1}+[gui_fmt.txt_w/2 0 -gui_fmt.txt_w/2 0],'callback',{@update_cback,main_figure});
echo_int_tab_comp.tog_tfreq=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.popumenuStyle,'String',{'--'},'Value',1,'Position',pos{init_disp+2,1}{2}-[0 0 gui_fmt.txt_w/2 0],'callback',{@update_cback,main_figure});
uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.txtStyle,'String','X-Axis ','Position',pos{init_disp+3,1}{1}-[0 0 gui_fmt.txt_w/2 0]);

echo_int_tab_comp.tog_xaxis=uicontrol(echo_int_tab_comp.opt_panel,gui_fmt.popumenuStyle,'String',xaxis_opt,...
    'Value',2,'Position',pos{init_disp+3,1}{1}+[ gui_fmt.txt_w/2 0 0 0],'callback',{@update_cback,main_figure});


echo_int_tab_comp.l_v=linkprop([echo_int_tab_comp.main_ax echo_int_tab_comp.v_ax],'YTick');
echo_int_tab_comp.l_h=linkprop([echo_int_tab_comp.main_ax echo_int_tab_comp.h_ax],'XTick');

setappdata(main_figure,'EchoInt_tab',echo_int_tab_comp);

if ~isempty(layer_obj)
    update_echo_int_tab(main_figure,1);
end

resize_echo_int_cback([],[],main_figure);

end
function update_cback(src,evt,main_figure)
update_echo_int_tab(main_figure,0);
end

function slice_transect_cback(src,evt,main_figure)

load_bar_comp=show_status_bar(main_figure);
load_bar_comp.progress_bar.setText('Slicing transect...');

update_survey_opts(main_figure);
echo_int_tab_comp=getappdata(main_figure,'EchoInt_tab');

layer_obj=get_current_layer();
if isempty(layer_obj)
    return;
end

survey_options_obj=layer_obj.get_survey_options();

idx_main=get(echo_int_tab_comp.tog_freq,'value');

[trans_obj,idx_freq]=layer_obj.get_trans(layer_obj.ChannelID{idx_main});
reg_type=echo_int_tab_comp.reg_id_box.String;
reg_types=strsplit(reg_type,';');

switch echo_int_tab_comp.tog_int.String{echo_int_tab_comp.tog_int.Value}
    case 'All Data Regions'
        idx_reg=trans_obj.find_regions_type('Data');
    case 'ID'
        reg_types=str2double(reg_types);
        idx_reg=trans_obj.find_regions_ID(reg_types);
    case 'Tag'
        idx_reg=trans_obj.find_regions_tag(reg_types);
    case 'Name'
        idx_reg=trans_obj.find_regions_name(reg_types);
end

show_status_bar(main_figure);
try
    
    if echo_int_tab_comp.all_freq.Value>0
        idx_sec=1:numel(layer_obj.Frequencies);
    else
        idx_sec=idx_main;
    end
        
        layer_obj.multi_freq_slice_transect2D(...
        'idx_main_freq',idx_main,...
        'idx_sec_freq',idx_sec,...
        'idx_regs',idx_reg,...
        'regs',region_cl.empty(),...
        'survey_options',survey_options_obj,...
        'load_bar_comp',getappdata(main_figure,'Loading_bar'));
    
    
catch err
    print_errors_and_warnings(1,'error',err);
    return;
end

hide_status_bar(main_figure);
freqs_out=layer_obj.Frequencies(layer_obj.EchoIntStruct.idx_freq_out);
idx_main=find(layer_obj.Frequencies(idx_freq)==freqs_out);
set(echo_int_tab_comp.tog_tfreq,'String',num2str(freqs_out'/1e3,'%.0f kHz'),'Value',idx_main);
setappdata(main_figure,'EchoInt_tab',echo_int_tab_comp);

ref={'Surface','Bottom','Transducer'};
idx=find(ismember(ref,layer_obj.EchoIntStruct.output_2D_type{1}));
if ~isempty(idx)
    set(echo_int_tab_comp.tog_ref,'String',ref(idx));
    set(echo_int_tab_comp.tog_ref,'Value',1);
end

update_echo_int_tab(main_figure,0);

hide_status_bar(main_figure);
end

function export_cback(src,evt,main_figure)
echo_int_tab_comp=getappdata(main_figure,'EchoInt_tab');
idx_main_freq=get(echo_int_tab_comp.tog_freq,'value');
layer_obj=get_current_layer();

if isempty(layer_obj.EchoIntStruct)
    return;
end

layer=get_current_layer();
if isempty(layer)
    return;
end
idx_main=find(idx_main_freq==layer_obj.EchoIntStruct.idx_freq_out);

if isempty(idx_main)||isempty(layer_obj.EchoIntStruct.output_2D)
    warndlg_perso(main_figure,'Nothing to export','No echo-integration results to export. Re-run the echo-integration...');
    return;
end

[path_tmp,fileN,~]=fileparts(layer.Filename{1});

path_tmp = uigetdir(path_tmp,...
    'Save Sliced transect to folder');
if isequal(path_tmp,0)
    return;
end

load_bar_comp=show_status_bar(main_figure);
load_bar_comp.progress_bar.setText('Exporting Sliced transect...');



if ~isempty(layer_obj.EchoIntStruct.reg_descr_table)
    output_f=[fullfile(path_tmp,fileN) '_regions_descr.csv'];
    if exist(output_f,'file')>1
        delete(output_f);
    end
    writetable(layer_obj.EchoIntStruct.reg_descr_table,output_f);
end
str_freq=num2str(layer_obj.Frequencies(idx_main_freq));

for it=1:numel(layer_obj.EchoIntStruct.output_2D{idx_main})
    if ~isempty(layer_obj.EchoIntStruct.output_2D{idx_main}{it})
        fname=generate_valid_filename([fileN '_' layer_obj.EchoIntStruct.output_2D_type{idx_main}{it} '_' str_freq '_sliced_transect.csv']);
        output_f=fullfile(path_tmp,fname);
        reg_output_table=reg_output_to_table(layer_obj.EchoIntStruct.output_2D{idx_main}{it});
        writetable(reg_output_table,output_f);
    end
end

disp_done_figure(main_figure,'Echo-integration finished and exported... Done')
hide_status_bar(main_figure);
end


function resize_echo_int_cback(~,~,main_figure)
echo_int_tab_comp=getappdata(main_figure,'EchoInt_tab');

switch echo_int_tab_comp.echo_int_tab.Type
    case 'uitab'
        pos_tab=getpixelposition(echo_int_tab_comp.echo_int_tab);
        pos_tab(4)=pos_tab(4);
    case 'figure'
        pos_tab=getpixelposition(echo_int_tab_comp.echo_int_tab);
end
opt_panel_size=[0 pos_tab(4)-500+1 300 500];
ax_panel_size=[opt_panel_size(3) 0 pos_tab(3)-opt_panel_size(3) pos_tab(4)];
set(echo_int_tab_comp.opt_panel,'position',opt_panel_size);
set(echo_int_tab_comp.ax_panel,'position',ax_panel_size);
end
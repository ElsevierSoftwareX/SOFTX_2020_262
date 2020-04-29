function load_map_tab(main_figure,tab_panel,varargin)

p = inputParser;
addRequired(p,'main_figure',@(obj) isa(obj,'matlab.ui.Figure'));
addRequired(p,'tab_panel',@(obj) ishghandle(obj));
addParameter(p,'cont_disp',0,@isnumeric);
addParameter(p,'cont_val',500,@isnumeric);
addParameter(p,'basemap','landcover',@ischar);
addParameter(p,'idx_lays',[],@isnumeric);
addParameter(p,'all_lays',0,@isnumeric);
parse(p,main_figure,tab_panel,varargin{:});

map_tab_comp.idx_lays=p.Results.idx_lays;


switch tab_panel.Type
    case 'uitabgroup'
        map_tab_comp.map_tab=new_echo_tab(main_figure,tab_panel,'Title','Map','UiContextMenuName','map');
    case 'figure'
        map_tab_comp.map_tab=tab_panel;
end

set(map_tab_comp.map_tab,'ResizeFcn',{@resize_map_tab,main_figure})

size_tab=getpixelposition(map_tab_comp.map_tab);

height=size_tab(4);
size_opt=[0 0 175 height];
ax_size=[size_opt(3)+size_opt(1) 0 size_tab(3)-size_opt(3) size_tab(4)];
map_tab_comp.opt_panel=uibuttongroup(map_tab_comp.map_tab,'units','pixels','Position',size_opt,'Title','Options','background','white');

gui_fmt=init_gui_fmt_struct();
gui_fmt.txt_w=gui_fmt.txt_w;
pos=create_pos_3(7,2,gui_fmt.x_sep,gui_fmt.y_sep,gui_fmt.txt_w,gui_fmt.box_w,gui_fmt.box_h);
%
%  uicontrol(...
% 'Parent',multi_freq_tab.setting_panel,...
% 'String','Diap',...
% gui_fmt.txtTitleStyle,...
% 'Position',pos{1,2}{1}+[0 0 gui_fmt.box_w 0],...
% 'Callback','');

map_tab_comp.cont_disp=p.Results.cont_disp;
map_tab_comp.cont_val=p.Results.cont_val;
map_tab_comp.idx_lays=p.Results.idx_lays;
map_tab_comp.all_lays=p.Results.all_lays;

map_tab_comp.cont_checkbox=uicontrol(...
    'Parent',map_tab_comp.opt_panel,...
    'String','Contours(m)',...
    gui_fmt.chckboxStyle,...
    'Position',pos{1,1}{1},...
    'Callback',{@update_map_cback,main_figure},'Value',p.Results.cont_disp);

map_tab_comp.contour_edit_box=uicontrol(...
    'Parent',map_tab_comp.opt_panel,...
    'String',num2str(p.Results.cont_val),...
    gui_fmt.edtStyle,...
    'Position',pos{1,1}{2},...
    'Callback',{@update_map_cback,main_figure});

curr_disp=get_esp3_prop('curr_disp');

if isempty(curr_disp)||~isdeployed
    base_curr=p.Results.basemap;   
    [basemap_list,~,~,basemap_dispname_list]=list_basemaps(~isdeployed,curr_disp.Online);
else
    base_curr=curr_disp.Basemap;
    [basemap_list,~,~,basemap_dispname_list]=list_basemaps(~isdeployed,curr_disp.Online,curr_disp.Basemaps);
end

idx=find(strcmpi(base_curr,basemap_list));

if isempty(idx)
    idx=1;
end

map_tab_comp.basemap_list=uicontrol(...
    'Parent',map_tab_comp.opt_panel,...
    'String',basemap_dispname_list,...
    gui_fmt.popumenuStyle,...
    'Position',pos{2,1}{1},...
    'Callback',{@update_basemap_cback,main_figure},'Value',idx,'UserData',basemap_list);

uicontrol(...
    'Parent',map_tab_comp.opt_panel,...
    'String','Zoom to :',...
    gui_fmt.txtTitleStyle,...
    'Position',pos{3,1}{1});

map_tab_comp.rad_curr=uicontrol(...
    'Parent',map_tab_comp.opt_panel,...
    'String','current layer',...
    gui_fmt.radbtnStyle,...
    'Position',pos{4,1}{1},...
    'Callback',{@update_map_cback,main_figure},'Value',p.Results.all_lays==0);

map_tab_comp.rad_all=uicontrol(...
    'Parent',map_tab_comp.opt_panel,...
    'String','all layers',...
    gui_fmt.radbtnStyle,...
    'Position',pos{5,1}{1},...
    'Callback',{@update_map_cback,main_figure},'Value',p.Results.all_lays>0);


map_tab_comp.rad_curr=uicontrol(...
    'Parent',map_tab_comp.opt_panel,...
    'String','Boat position :',...
    gui_fmt.txtTitleStyle,...
    'Position',pos{6,1}{1});

map_tab_comp.update_boat_pos=uicontrol(...
    'Parent',map_tab_comp.opt_panel,...
    'String','update',...
    gui_fmt.chckboxStyle,...
    'Position',pos{7,1}{1},...
    'Value',1);

map_tab_comp.ax=geoaxes('Parent',map_tab_comp.map_tab,...
    'Units','pixels',...
    'OuterPosition',ax_size,...
    'visible','on',....
    'basemap',basemap_list{idx},...
    'ActivePositionProperty','position');

format_geoaxes(map_tab_comp.ax);

geolimits(map_tab_comp.ax,[-90 90],[-180 180]);

map_tab_comp.boat_pos=matlab.graphics.chart.primitive.Line('Parent',map_tab_comp.ax,'marker','s','markersize',10,'markeredgecolor','r','markerfacecolor','k','tag','boat_pos');
map_tab_comp.boat_pos.LatitudeDataMode='manual';
map_tab_comp.curr_track=matlab.graphics.chart.primitive.Line('Parent',map_tab_comp.ax,'Color','r','linestyle','--','linewidth',1,'tag','curr_track');
map_tab_comp.curr_track.LatitudeDataMode='manual';

map_tab_comp.tracks_plots=[];
map_tab_comp.map_info=[];
map_tab_comp.contour_plots=[];
map_tab_comp.contour_texts=[];
map_tab_comp.shapefiles_plot=[];

setappdata(main_figure,'Map_tab',map_tab_comp);

update_map_tab(main_figure);

end

function resize_map_tab(src,evt,main_figure)
try
    map_tab_comp=getappdata(main_figure,'Map_tab');
    size_tab=getpixelposition(map_tab_comp.map_tab);
    
    height=size_tab(4);
    size_opt=[0 0 175 height];
    ax_size=[size_opt(3)+size_opt(1) 0 size_tab(3)-size_opt(3) size_tab(4)];
    
    set(map_tab_comp.opt_panel,'Position',size_opt);
    set(map_tab_comp.ax,'OuterPosition',ax_size);
    
end
end

function update_map_cback(src,evt,main_figure)

update_map_tab(main_figure,'src',src);

end

function update_basemap_cback(src,evt,main_figure)
map_tab_comp=getappdata(main_figure,'Map_tab');

basemap_str=map_tab_comp.basemap_list.UserData{map_tab_comp.basemap_list.Value};
curr_disp=get_esp3_prop('curr_disp');
curr_disp.Basemap=basemap_str;
geobasemap(map_tab_comp.ax,basemap_str);
if isappdata(main_figure,'file_tab')
    file_tab_comp=getappdata(main_figure,'file_tab');
    geobasemap(file_tab_comp.map_axes,basemap_str);
end

end
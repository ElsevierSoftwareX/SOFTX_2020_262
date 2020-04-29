function load_map_fig(main_figure,obj_vec,varargin)

%% input parser

p = inputParser;
addRequired(p,'main_figure',@ishandle);
addRequired(p,'obj_vec',@(obj) isa(obj,'mbs_cl')||isa(obj,'survey_cl')||isempty(obj));
parse(p,main_figure,obj_vec,varargin{:});

%% processing

if isempty(obj_vec)
    
    layers = get_esp3_prop('layers');
    
    [box.lat_lim,box.lon_lim,box.lat_lays,box.lon_lays] = get_lat_lon_lim(layers);

    
    list_Str = list_layers(layers);
    
else
    
    [box.lat_lim,box.lon_lim,box.lat_lays,box.lon_lays] = get_lat_lon_lim(obj_vec);
    
    idx_empty=find(cellfun(@(x) isempty(x),box.lat_lays)|cellfun(@(x) all(x==0),box.lat_lays));
    box.lat_lays(idx_empty)=[];
    box.lon_lays(idx_empty)=[];
    
    obj_vec(idx_empty)=[];
    
    switch class(obj_vec)
        case 'mbs_cl'
            list_Str = list_mbs(obj_vec);
        case 'survey_cl'
            list_Str = list_survey(obj_vec);
    end
end


[box.lat_lim,box.lon_lim] = ext_lat_lon_lim_v2(box.lat_lim,box.lon_lim,0.2);


if nansum(isnan(box.lat_lim)) == 2
    return;
end

box.slice_size = 10;
box.val_max = 0.000001;
box.r_max = 2;
box.nb_pts = 100;

box.depth_contour_size = 1000;

map_fig = new_echo_figure(main_figure,'Units','pixels','Position',[100 100 800 600],...
    'Resize','off',...
    'Name','Integration Map','tag','intemap');

curr_disp=get_esp3_prop('curr_disp');

if isempty(curr_disp)
    base_curr=p.Results.basemap;   
    [basemap_list,~,~,basemap_dispname_list]=list_basemaps(0,curr_disp.Online);
else
    base_curr=curr_disp.Basemap;
    [basemap_list,~,~,basemap_dispname_list]=list_basemaps(0,curr_disp.Online,curr_disp.Basemaps);
end


box.lim_axes = geoaxes('Parent', map_fig,...
    'Units','normalized',...
    'OuterPosition',[0 0.2 0.75 0.8],...
    'Tag','map','basemap',base_curr);
format_geoaxes(box.lim_axes);

box.listbox = uicontrol(map_fig,'Style','listbox',...
    'Units','normalized',...
    'Position',[0.7 0.6 0.25 0.35],...
    'String',list_Str,...
    'BackgroundColor','w',...
    'Max',2,...
    'Tag','listbox',...
    'Callback',{@update_map_callback,map_fig});

switch class(obj_vec)
    case 'mbs_cl'
        field_str = {'SliceAbscf'};
    case 'survey_cl'
        field_str = {'SliceAbscf','Nb_ST','Nb_Tracks','Tag'};
    otherwise
        field_str = {'SliceAbscf','Nb_ST','Nb_Tracks'};
end

type_str = {'Log10', 'Square Root', 'Linear'};

uicontrol(map_fig,'Style','text','BackgroundColor','White',...
    'Units','normalized',...
    'Position',[0.3 0.15 0.25 0.05],...
    'BackgroundColor','w',...
    'String','Variable to plot and scale:');

box.field = uicontrol(map_fig,'Style','popupmenu',...
    'Units','normalized',...
    'Position',[0.3 0.1 0.2 0.05],...
    'String',field_str,...
    'Callback',{@update_field_callback,map_fig});

box.plottype = uicontrol(map_fig,'Style','popupmenu',...
    'Units','normalized',...
    'Position',[0.3 0.025 0.2 0.05],...
    'String',type_str);

idx=find(strcmp(base_curr,basemap_list));

if isempty(idx)
    idx=1;
end
uicontrol(map_fig,'Style','text','BackgroundColor','White',...
    'Units','normalized',...
    'Position',[0.6 0.15 0.12 0.05],...
    'BackgroundColor','w',...
    'String','Basemap:');

box.tog_basemap = uicontrol(map_fig,'Style','popupmenu','String',basemap_dispname_list,'Value',idx,...
    'units','normalized','Position', [0.6 0.1 0.1 0.05],'Callback',{@init_map,map_fig},'UserData',basemap_list);

uicontrol(map_fig,'Style','text','BackgroundColor','White',...
    'Units','normalized',...
    'Position',[0.725 0.15 0.12 0.05],...
    'BackgroundColor','w',...
    'String','Disk Color:');

box.tog_circle_color = uicontrol(map_fig,'Style','popupmenu','String',{'Proportional' 'Red' 'Yellow' 'Green' 'Blue' 'Black' 'White'},'Value',1,...
    'units','normalized','Position', [0.725 0.1 0.1 0.05]);

box.hist_ax = axes(map_fig,'units','normalized','OuterPosition', [0.7 0.25 0.25 0.35],'Box','on','XGrid','off','Ygrid','off','visible','off','YTick',[],'YTickLabels',{});

box.depth_box = uicontrol(map_fig,'Style','checkbox','Value',0,...
    'String','Depth Contours every (m)','units','normalized','Position',[0.6 0.2 0.25 0.05],...
    'BackgroundColor','w',...
    'callback',{@update_map_callback,map_fig});

box.depth_contour_box = uicontrol(map_fig,'Style','edit',...
    'Units','normalized',...
    'Position',[0.85 0.2 0.05 0.05],...
    'String',num2str(box.depth_contour_size,'%d'),...
    'BackgroundColor','w',...
    'Tag','slice_size','Callback',{@check_depth_contour_size,map_fig});

uicontrol(map_fig,'Style','text','BackgroundColor','White',...
    'Units','normalized',...
    'Position',[0.025 0.175 0.125 0.05],...
    'BackgroundColor','w',...
    'String','Slice (pings):');

box.slice_size_box = uicontrol(map_fig,'Style','edit',...
    'Units','normalized',...
    'Position',[0.175 0.175 0.1 0.05],...
    'String',num2str(box.slice_size,'%d'),...
    'BackgroundColor','w',...
    'Tag','slice_size','Callback',{@check_slice_size,map_fig});

if ~isempty(obj_vec)
    set(box.slice_size_box,'enable','off');
    switch class(obj_vec)
        case 'survey_cl'
            set(box.slice_size_box,'String',num2str(obj_vec(1).SurvInput.Options.Vertical_slice_size,'%d'));
        case 'mbs_cl'
            % nothing?
    end
end

str_field = get(box.field,'string');

str_field = str_field{get(box.field,'value')};

box.str_field = uicontrol(map_fig,'Style','text','BackgroundColor','White',...
    'Units','normalized',...
    'BackgroundColor','w',...
    'Position',[0.025 0.1 0.125 0.05],...
    'String',sprintf('%s',str_field));

box.val_max_box = uicontrol(map_fig,'Style','edit',...
    'Units','normalized',...
    'Position',[0.175 0.1 0.1 0.05],...
    'String',num2str(box.val_max,'%.8g'),...
    'BackgroundColor','w',...
    'Tag','slice_size','Callback',{@check_val_max,map_fig});

uicontrol(map_fig,'Style','text','BackgroundColor','White',...
    'Units','normalized',...
    'Position',[0.025 0.025 0.125 0.05],...
    'BackgroundColor','w',...
    'String','R(km):');

box.r_max_box = uicontrol(map_fig,'Style','edit',...
    'Units','normalized',...
    'Position',[0.175 0.025 0.1 0.05],...
    'String',num2str(box.r_max,'%.2f'),...
    'BackgroundColor','w',...
    'Tag','slice_size','Callback',{@check_r_max,map_fig});

uicontrol(map_fig,'Style','pushbutton','units','normalized',...
    'string','Create Map','pos',[0.85 0.025 0.1 0.05],...
    'TooltipString', 'Create Map',...
    'HorizontalAlignment','left','BackgroundColor','white','callback',{@create_map_callback,map_fig,main_figure,obj_vec});


setappdata(map_fig,'Box',box);
setappdata(map_fig,'obj_vec',obj_vec);
init_map([],[],map_fig);

set(map_fig,'visible','on');
update_map_callback([],[],map_fig);

end




%% subfunctions/callbacks

function init_map(~,~,map_fig)

box=getappdata(map_fig,'Box');

cla(box.lim_axes);
hold(box.lim_axes,'on');

basemap_str=box.tog_basemap.UserData{box.tog_basemap.Value};
set(box.lim_axes,'basemap',basemap_str)

index_selected = get(box.listbox,'Value');

for i=1:length(box.lat_lays)
    if ~isempty(box.lat_lays{i})
        if any(index_selected==i)
            box.trans(i)=geoplot(box.lat_lays{i},box.lon_lays{i},'color','r','linewidth',2,'linestyle','none','marker','.','parent',box.lim_axes);
        else
            box.trans(i)=geoplot(box.lat_lays{i},box.lon_lays{i},'color','k','linewidth',1,'linestyle','none','marker','.','parent',box.lim_axes);
        end
    end
end

if box.depth_box.Value>0
    try
        [box.hs,box.ht]=plot_cont_from_etopo1(box.lim_axes,box.depth_contour_size);
    catch
        box.ht=[];
        box.hs=[];
        disp('No Geographical data available...');
    end
else
    box.ht=[];
    box.hs=[];
end


setappdata(map_fig,'Box',box);
end

function update_field_callback(~,~,map_fig)

box=getappdata(map_fig,'Box');

str_field=get(box.field,'string');
str_field=str_field{get(box.field,'value')};

switch (str_field)
    case 'SliceAbscf'
        box.val_max=0.00001;
    case 'Nb_ST'
        box.val_max=20;
    case 'Nb_Tracks'
        box.val_max=10;
    case 'Tag'
        box.val_max=0.00001;
end

set(box.val_max_box,'string',num2str(box.val_max,'%.6f'));
set(box.str_field,'String',sprintf('%s',str_field));
update_hist([],[],map_fig);
end

function update_hist(~,~,map_fig)
box=getappdata(map_fig,'Box');

obj_vec=getappdata(map_fig,'obj_vec');
if isempty(obj_vec)
    set(box.hist_ax,'visible','off');
    set(box.hist_ax.Children,'visible','off');
else
    
    index_selected = get(box.listbox,'Value');
    obj_vec=obj_vec(index_selected);
    set(box.hist_ax,'visible','on');
   
    values=[];
    for ui=1:numel(obj_vec)
        str_field=get(box.field,'string');
        str_field=str_field{get(box.field,'value')};
        if isempty(obj_vec(ui).SurvOutput)
            continue;
        end
        switch str_field
            case 'SliceAbscf'
                tmp=obj_vec(ui).SurvOutput.slicedTransectSum.slice_abscf;
            case 'Nb_ST'
                tmp=obj_vec(ui).SurvOutput.slicedTransectSum.slice_nb_st;
            case 'Nb_Tracks'
                tmp=obj_vec(ui).SurvOutput.slicedTransectSum.slice_nb_tracks;
            case 'Tag'
                set(box.hist_ax,'visible','off');
                set(box.hist_ax.Children,'visible','off');
                return;
        end
        values=[values [tmp{:}]];
    end
    values(values==0)=[];
    if isempty(values)
        set(box.hist_ax,'visible','off');
        set(box.hist_ax.Children,'visible','off');
        return;
    end
    histogram(box.hist_ax,values,'BinMethod','fd');
    title(box.hist_ax,sprintf('Min: %f\n Max: %f',nanmin(values),nanmax(values)))
    set(box.hist_ax,'YTickLabels',{});
    switch str_field
        case 'SliceAbscf'
            box.hist_ax.XAxis.Scale='log';
        otherwise
            box.hist_ax.XAxis.Scale='linear';
    end
end

end


function update_map_callback(~,~,map_fig)

box=getappdata(map_fig,'Box');
index_selected = get(box.listbox,'Value');

for i=1:length(box.lat_lays)
    if isa(box.trans(i),'matlab.graphics.chart.primitive.Line')
        if any(index_selected==i)
            set(box.trans(i),'color','r','linewidth',2);
        else
            set(box.trans(i),'color','k','linewidth',1);
        end
    end
end
id_em=find(cellfun(@isempty,box.lat_lays));
index_selected=setdiff(index_selected,id_em);
if isempty(index_selected)
    return;
end

latlim=[nanmin(cellfun(@nanmin,box.lat_lays(index_selected))) nanmax(cellfun(@nanmax,box.lat_lays(index_selected)))];
lonlim=[nanmax(cellfun(@nanmin,box.lon_lays(index_selected))) nanmax(cellfun(@nanmax,box.lon_lays(index_selected)))];
[latlim,lonlim]=ext_lat_lon_lim_v2(latlim,lonlim,0.1);
geolimits(box.lim_axes,latlim,lonlim);

if get(box.depth_box,'Value')>0
    if ~isempty(box.hs)
        set(box.hs,'visible','on');
        set(box.ht,'visible','on');
    else
        try
            [box.hs,box.ht]=plot_cont_from_etopo1(box.lim_axes,box.depth_contour_size);
        catch
            box.ht=[];
            box.hs=[];
            disp('No Geographical data available...');
        end
    end
else
    set(box.hs,'visible','off');
    set(box.ht,'visible','off');
end



update_hist([],[],map_fig);

end

function check_r_max(src,~,map_fig)
box=getappdata(map_fig,'Box');
str=get(src,'string');
if isnan(str2double(str))||str2double(str)<=0
    set(src,'string',num2str(box.r_max,'%.2f'));
else
    box.r_max=str2double(str);
    set(src,'string',num2str(box.r_max,'%.2f'));
end
setappdata(map_fig,'Box',box);
end

function check_val_max(src,~,map_fig)
box=getappdata(map_fig,'Box');
str=get(src,'string');
if isnan(str2double(str))||str2double(str)<=0
    set(src,'string',num2str(box.val_max,'%.8g'));
else
    box.val_max=str2double(str);
    set(src,'string',num2str(box.val_max,'%.8g'));
end
setappdata(map_fig,'Box',box);
end

function check_slice_size(src,~,map_fig)
box=getappdata(map_fig,'Box');
str=get(src,'string');
if isnan(str2double(str))||str2double(str)<=0
    set(src,'string',num2str(box.slice_size,'%d'));
else
    box.slice_size=ceil(str2double(str));
    set(src,'string',num2str(box.slice_size,'%d'));
end
setappdata(map_fig,'Box',box);
end


function check_depth_contour_size(src,~,map_fig)
box=getappdata(map_fig,'Box');
str=get(src,'string');
if isnan(str2double(str))||str2double(str)<=0
    set(src,'string',num2str(box.depth_contour_size,'%d'));
else
    box.depth_contour_size=ceil(str2double(str));
    set(src,'string',num2str(box.depth_contour_size,'%d'));
end
setappdata(map_fig,'Box',box);
init_map([],[],map_fig);
end

% callback for "Create Map" push button
function create_map_callback(~,~,map_fig,main_figure,obj_vec_tot)

box = getappdata(map_fig,'Box');
hfigs = getappdata(main_figure,'ExternalFigures');
curr_disp=get_esp3_prop('curr_disp');
index_selected = get(box.listbox,'Value');

if get(box.depth_box,'Value')>0
    cont = box.depth_contour_size;
else
    cont = 0;
end

id_em=find(cellfun(@isempty,box.lat_lays));
index_selected=setdiff(index_selected,id_em);
if isempty(index_selected)
    return;
end

if isempty(obj_vec_tot)
    layers = get_esp3_prop('layers');
    obj = layers(index_selected);
else
    obj = obj_vec_tot(index_selected);
end
basemap_str=box.tog_basemap.UserData{box.tog_basemap.Value};
str_field = get(box.field,'string');
str_field = str_field{get(box.field,'value')};

str_type = get(box.plottype,'string');
p_type=str_type{get(box.plottype,'value')};

cc_type = get(box.tog_circle_color,'string');
cc=cc_type{get(box.tog_circle_color,'value')};


if isempty(obj_vec_tot)
    map_input = map_input_cl.map_input_cl_from_obj(obj,'ValMax',box.val_max,'Rmax',box.r_max,'SliceSize',box.slice_size,'Basemap',basemap_str,'Depth_Contour',cont,'Freq',curr_disp.Freq);
    if isempty(map_input)
        return;
    end
    map_input.PlotType = p_type;
else
    for ui = 1:length(obj)
        map_input(ui) = map_input_cl.map_input_cl_from_obj(obj(ui),'ValMax',box.val_max,'Rmax',box.r_max,'SliceSize',box.slice_size,'Basemap',basemap_str,'Depth_Contour',cont);
        map_input(ui).PlotType = p_type;
    end
    %map_input = map_input.concatenate_map_input();
end
 folders={};
switch class(obj)
    case 'layer_cl'
        [folders,~]=obj.get_path_files();
        folders=unique(folders);
    case 'survey_cl'
        for ui=1:numel(obj)
            tmp=obj(ui).SurvInput.list_data_folders();
            folders=unique([folders tmp]);
        end      
end

[cmap,col_ax,col_lab,col_grid,col_bot,col_txt,~]=init_cmap(curr_disp.Cmap);

% create the map here
% box.lim_axes.LatitudeLimits
% box.lim_axes.LatitudeLimits
hfig = map_input.display_map_input_cl('main_figure',main_figure,'field',str_field,'LatLim',[],'LongLim',[],'Colormap',cmap,'coloredCircle',cc,'echomaps',folders);

hfigs_new = [hfigs hfig];
setappdata(main_figure,'ExternalFigures',hfigs_new);
% delete(map_fig);

end


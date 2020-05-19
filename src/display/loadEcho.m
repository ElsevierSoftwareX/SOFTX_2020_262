%% loadEcho.m
%
% TODO
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
%
% *OUTPUT VARIABLES*
%
% NA
%
% *RESEARCH NOTES*
%
% TODO
%
% *NEW FEATURES*
%
% * 2017-03-22: header and comments updated according to new format (Alex Schimel)
% * 2017-03-13: comments and header (Alex Schimel)
% * YYYY-MM-DD: first version (Yoann Ladroit)
%
% *EXAMPLE*
%
% TODO
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, NIWA. Type |help EchoAnalysis.m| for copyright information.

%% Function
function loadEcho(main_figure,varargin)

if ~isdeployed
    disp_perso(main_figure,'loadEcho');
    tic;
end
if isempty(main_figure)
    return;
end

layer  = get_current_layer();
layers = get_esp3_prop('layers');

if isempty(layers)
    return;
end

curr_disp=get_esp3_prop('curr_disp');

remove_interactions(main_figure);
disable_listeners(main_figure);

uiundo(main_figure,'clear');

load_bar_comp=getappdata(main_figure,'Loading_bar');
lay_str=list_layers(layer);
    

disp_perso(main_figure,sprintf('Loading layer %s',lay_str{1}));
nb_layers = length(layers);

try
     if all(ismember(layer.ChannelID,curr_disp.AllChannels))...
            &&all(ismember(curr_disp.AllChannels,layer.ChannelID))
        up_curr_disp=0;
    else
        up_curr_disp=1;
     end
    
    if strcmp(layer.Unique_ID,curr_disp.CurrLayerID) ...
            &&nb_layers==curr_disp.NbLayers...
            &&all(ismember(layer.ChannelID,curr_disp.AllChannels))...
            &&all(ismember(curr_disp.AllChannels,layer.ChannelID))
        flag = 0;
    else
        flag = 1; 
    end
    
catch
    flag = 1;
    up_curr_disp=1;
    if ~isdeployed()
        disp_perso(main_figure,'Error in Load Echo');
    end
end

if up_curr_disp>=1
    [display_config_file,~,~]=get_config_files();
    [~,fname,fext]=fileparts(display_config_file);
    filepath=fileparts(layer.Filename{1});
    disp_config_file=fullfile(filepath,[fname fext]);
    
    if isfile(disp_config_file)
        curr_disp_new=read_config_display_xml(disp_config_file);
        props=properties(curr_disp);
        
        for i=1:numel(props)
            if ~ismember((props{i}),{'Basemap' 'Basemaps' 'Fieldnames' 'Fieldname' 'Type' 'Xaxes_current' 'Cax' 'Caxes' 'Freq' 'DispSecFreqs' 'Cmap' 'DispSecFreqsOr' 'DispSecFreqsWithOffset' 'EchoType' 'EchoQuality'})
                curr_disp.(props{i})=curr_disp_new.(props{i});
            end
        end
    end
end

curr_disp.CurrLayerID = layer.Unique_ID;
curr_disp.NbLayers    = nb_layers;
curr_disp.SecChannelIDs=layer.ChannelID;
curr_disp.SecFreqs=layer.Frequencies;
curr_disp.AllChannels=layer.ChannelID;

[trans_obj,idx_freq]=layer.get_trans(curr_disp);

if isempty(trans_obj)
    idx_freq = 1;
    %disp('Cannot Find Frequency...');
    curr_disp.ChannelID = layer.ChannelID{idx_freq};
    curr_disp.Freq = layer.Frequencies(idx_freq);
	[trans_obj,idx_freq]=layer.get_trans(curr_disp);
end

curr_disp.ChannelID = layer.ChannelID{idx_freq};

[~,found_field] = find_field_idx(trans_obj.Data,curr_disp.Fieldname);

if found_field == 0
    [~,found] = find_field_idx(trans_obj.Data,'sv');
    if found == 0
        field = trans_obj.Data.Fieldname{1};
    else
        field = 'sv';
    end
    curr_disp.setField(field);
end


%old_nb=curr_disp.NbLayers;

curr_disp.Bot_changed_flag = 0;
curr_disp.Reg_changed_flag = 0;
curr_disp.UIupdate=1;

curr_disp.setActive_reg_ID({});



if nargin>=3
    flag=varargin{1};
    f_update=varargin{2};   
else
   f_update=0; 
end
update_display(main_figure,flag,f_update);

waitfor(curr_disp,'UIupdate',0);

axes_panel_comp=getappdata(main_figure,'Axes_panel');
if isa(axes_panel_comp.axes_panel,'matlab.ui.container.Tab')
    if ~ismember(axes_panel_comp.axes_panel.Parent.SelectedTab.Tag,{'axes_panel' 'echoint_tab'})     
        axes_panel_comp.axes_panel.Parent.SelectedTab=axes_panel_comp.axes_panel;
    end
end

enable_listeners(main_figure);
initialize_interactions_v2(main_figure);

curr_disp.CursorMode=curr_disp.CursorMode;

update_info_panel([],[],1);
load_bar_comp.progress_bar.setText('');
if ~isdeployed
    fprintf(1,'Currently %.0f active objects in ESP3\n\n',numel(findobj(main_figure)));
end

if ~isdeployed
    %drawnow;
    disp_perso(main_figure,'loadEcho done');
    fprintf('%d graphical objects in ESP3\n',numel(findall(main_figure)));
    toc;
end


end


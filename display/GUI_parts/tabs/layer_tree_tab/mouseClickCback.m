function mouseClickcback(hTree, eventData, main_figure,tree_hh)  %#ok hTree is unused

if eventData.isMetaDown||eventData.getClickCount==2
    clickX = eventData.getX;
    clickY = eventData.getY;
    jtree = eventData.getSource;
    nodes=getSelectedNodes(tree_hh);
    IDs={};
    files={};
    for i=1:numel(nodes)
        usrdata=get(nodes(i),'userdata');
        if isfield(usrdata,'ids')
            IDs=union(IDs,usrdata.ids);
            switch usrdata.level
                case 'file'
                    files=union(files,usrdata.files);
            end
        end
    end
    
    if eventData.isMetaDown  % right-click is like a Meta-button
        switch usrdata.level
            case 'root'
                jmenu = setRootContextMenu(main_figure);
            otherwise
                jmenu = setTreeContextMenu(main_figure,IDs,files);
        end
        try
            % Display the (possibly-modified) context menu
            jmenu.show(jtree, clickX, clickY);
            jmenu.repaint;
        catch
        end
    elseif eventData.getClickCount==2
        treePath = jtree.getPathForLocation(clickX, clickY);
        if~isempty(treePath)
            layers=get_esp3_prop('layers');
            layer=get_current_layer();
            selNode = treePath.getLastPathComponent;
            userdata=selNode.handle.UserData;
            if isempty(userdata)
                return;
            end
            switch userdata.level
                case 'layer'
                    if strcmp(layer.Unique_ID,userdata.ids)
                        return;
                    end
                    if contains(userdata.ids,IDs)
                        [idx,~]=find_layer_idx(layers,userdata.ids);
                        set_esp3_prop('layers',layers);
                        set_current_layer(layers(idx));
                        check_saved_bot_reg(main_figure);
                            show_status_bar(main_figure,1);

                        loadEcho(main_figure);
                        hide_status_bar(main_figure);

                    end
            end
            
        end
        
    end
end
end

function jmenu = setRootContextMenu(main_figure)

import javax.swing.*


menuLayItem0 = JMenuItem('Sort by Folder');
menuLayItem1 = JMenuItem('Sort by Survey Data');


set(handle(menuLayItem0,'CallbackProperties'), 'ActionPerformedCallback',{@sort_layer_tree_tab,main_figure,'folder'});
set(handle(menuLayItem1,'CallbackProperties'), 'ActionPerformedCallback',{@sort_layer_tree_tab,main_figure,'surveydata'});

jmenu = JPopupMenu;
jmenu.add(menuLayItem0);
jmenu.add(menuLayItem1);

end

function sort_layer_tree_tab(~,~,main_figure,sort_method)
    update_tree_layer_tab(main_figure,sort_method);
end

function jmenu = setTreeContextMenu(main_figure,IDs,files)

import javax.swing.*

str_goto='<HTML><center><FONT color="Green"><b>Go to layer</b> (show echogram)</Font> ';
menuLayItem0 = JMenuItem(str_goto);
menuLayItem9 = JMenuItem('Load other channels');
menuLayItem10 = JMenuItem('Remove channels');
menuLayItem8 = JMenuItem('Edit layer Survey Data');
menuLayItem1 = JMenuItem('Merge Selected layers');
menuLayItem2 = JMenuItem('Split Selected Layers (per survey data)');
menuLayItem3 = JMenuItem('Split Selected Layers (per files)');
menuLayItem11 = JMenuItem('Remove  selected files');
menuLayItem4 = JMenuItem('Export Gps Data to Shapefile');
menuLayItem6 = JMenuItem('Export Gps Data to _gps_data.csv');
menuLayItem12 = JMenuItem('Plot Pitch/Roll/Heave analysis');
str_delete='<HTML><center><FONT color="Red"><b>Remove selected layers</b></Font> ';
menuLayItem5 = JMenuItem(str_delete);


set(handle(menuLayItem0,'CallbackProperties'), 'ActionPerformedCallback',{@open_selected_callback,main_figure,IDs});
set(handle(menuLayItem9,'CallbackProperties'), 'ActionPerformedCallback',{@load_other_channels_cback,main_figure,IDs,0});
set(handle(menuLayItem10,'CallbackProperties'), 'ActionPerformedCallback',{@load_other_channels_cback,main_figure,IDs,1});
set(handle(menuLayItem8,'CallbackProperties'), 'ActionPerformedCallback',{@edit_survey_data_layer_callback,main_figure,IDs});
set(handle(menuLayItem1,'CallbackProperties'), 'ActionPerformedCallback',{@merge_selected_callback,main_figure,IDs});
set(handle(menuLayItem2,'CallbackProperties'), 'ActionPerformedCallback',{@split_selected_callback,main_figure,IDs,1});
set(handle(menuLayItem3,'CallbackProperties'), 'ActionPerformedCallback',{@split_selected_callback,main_figure,IDs,0});
set(handle(menuLayItem11,'CallbackProperties'), 'ActionPerformedCallback',{@remove_selected_files_callback,main_figure,IDs,files});
set(handle(menuLayItem4,'CallbackProperties'), 'ActionPerformedCallback',{@export_gps_to_shapefile_callback,main_figure,IDs});
set(handle(menuLayItem6,'CallbackProperties'), 'ActionPerformedCallback',{@export_gps_to_csv_callback,main_figure,IDs,'_gps_data'});
set(handle(menuLayItem12,'CallbackProperties'), 'ActionPerformedCallback',{@pitch_roll_analysis_callback,main_figure,IDs});
set(handle(menuLayItem5,'CallbackProperties'), 'ActionPerformedCallback',{@delete_layer_callback,main_figure,IDs});

jmenu = JPopupMenu;
jmenu.add(menuLayItem0);
jmenu.add(menuLayItem9);
jmenu.add(menuLayItem10);
jmenu.add(menuLayItem8);
jmenu.add(menuLayItem1);
jmenu.add(menuLayItem2);
jmenu.add(menuLayItem3);
jmenu.add(menuLayItem11);
jmenu.add(menuLayItem4);
jmenu.add(menuLayItem6);
jmenu.add(menuLayItem5);
jmenu.add(menuLayItem12);
end

function load_other_channels_cback(~,~,main_figure,IDs,rem)

layers=get_esp3_prop('layers');
layer=get_current_layer();

selected_layers=IDs;
load_bar_comp = getappdata(main_figure,'Loading_bar');
if isempty(layer)
    return;
end

if isempty(selected_layers)
    return;
end
up_disp=0;
idx=nan(1,numel(selected_layers));
for i=1:length(selected_layers)
    [idx(i),~]=find_layer_idx(layers,selected_layers{i});
end
show_status_bar(main_figure);
idx_rem=[];
channels={};
try
    layers_Str_comp=list_layers(layers);
for i_lay=idx
    layer_obj=layers(i_lay);
    Filename=layer_obj.Filename{1};
    channels_open=deblank(layer_obj.ChannelID);
    ftype = get_ftype(Filename);
   
    switch ftype
        case {'EK80' 'EK60' 'ASL'}
            frequency=layer_obj.AvailableFrequencies;
            channels_tmp=deblank(layer_obj.AvailableChannelIDs);
        otherwise
            continue;
    end
    
    if isempty(frequency)
        continue;
    end
    
    if ~(numel(intersect(channels_tmp,channels))==numel(channels_tmp))
         channels=channels_tmp;
        if rem==0
            frequency_to_add=frequency(~ismember(channels,channels_open));
            channels_to_add=channels(~ismember(channels,channels_open));
            [frequency_to_add,idx_s] = sort(frequency_to_add);
            channels_to_add = channels_to_add(idx_s);
            
            str_d='Channels to load';
        else
            frequency_to_add=frequency(ismember(channels,channels_open));
            channels_to_add=channels(ismember(channels,channels_open));
            [frequency_to_add,idx_s] = sort(frequency_to_add);
            channels_to_add = channels_to_add(idx_s);
            str_d='Channels to remove';
        end
        list_freq_str = cellfun(@(x,y) sprintf('%.0f kHz: %s',x,y),num2cell(frequency_to_add/1e3), channels_to_add,'un',0);
        if isempty(list_freq_str)
            warndlg_perso(main_figure,layers_Str_comp{i_lay},[layers_Str_comp{i_lay} ': All Channels already loaded.'])
            continue;
        end
        
        [select,val] = listdlg_perso(main_figure,str_d,list_freq_str);
        if val==0 || isempty(select)
            continue;
        else
            %frequency_to_add = frequency_to_add(select);
            channels_to_add = channels_to_add(select);
        end
    else
        channels=channels_tmp;
    end
    
    if rem==0
        layer_obj.add_transceiver('load_bar_comp',load_bar_comp,'channel',channels_to_add)
    else
        layer_obj.remove_transceiver('load_bar_comp',load_bar_comp,'channel',channels_to_add)
    end
    if isempty(layer_obj.Frequencies)
        idx_rem=union(idx_rem,i_lay);
    end
    up_disp=1;
end
IDs_rem={layers(idx_rem).Unique_ID};
layers(idx_rem)=[];
catch err
    print_errors_and_warnings(1,'error',err);
end
hide_status_bar(main_figure);

if up_disp>0
    if isempty(layers)
        layer_obj=layer_cl.empty();
        set_esp3_prop('layers',layers);
        set_current_layer(layer_obj);
        update_display_no_layers(main_figure);
    else

        if contains(IDs_rem,layer.Unique_ID)
            layer=layers(1);
            set_current_layer(layer);
            clear_regions(main_figure,{},{});
        end
        set_esp3_prop('layers',layers);
        clear_regions(main_figure,{},{});
        loadEcho(main_figure);
       
    end
end
end


function remove_selected_files_callback(src,evt,main_figure,IDs,files)
layers=get_esp3_prop('layers');
layer=get_current_layer();
selected_layers=IDs;

if isempty(layer)
    return;
end

if isempty(selected_layers)
    return;
end
id_lay={};
layers_to_del=[];
for ifi=1:numel(files)
    [idx_lay,found]=find_layer_idx_files(layers,files{ifi});
    while found>0
        new_layers=layers(idx_lay(1)).split_layer();
        layers(idx_lay(1))=[];
        new_layers.load_echo_logbook_db();
        [idx_lay_del,~]=find_layer_idx_files(new_layers,files{ifi});
        layers_to_del=[layers_to_del new_layers(idx_lay_del)];
        new_layers(idx_lay_del)=[];

        if ~isempty(new_layers)
            new_layers=shuffle_layers(new_layers,'multi_layer',0);
        end
        
        if ~isempty(new_layers)
            id_lay=new_layers(end).Unique_ID;
            layers=[layers new_layers];
        end
        [idx_lay,found]=find_layer_idx_files(layers,files{ifi});
    end


end
set_esp3_prop('layers',layers);

if contains(layer.Unique_ID,IDs)&&~isempty(id_lay)
    [idx,~]=find_layer_idx(layers,id_lay);
    layer=layers(idx);
    
    set_current_layer(layer);
    %clear_regions(main_figure,{},{});
    loadEcho(main_figure);
else
    update_tree_layer_tab(main_figure);
end
if~isempty(layers_to_del)
    layers_to_del.delete_layers({});
end

end

function split_selected_callback(~,~,main_figure,IDs,id)
layers=get_esp3_prop('layers');
layer=get_current_layer();
selected_layers=IDs;

if isempty(layer)
    return;
end

if isempty(selected_layers)
    return;
end

idx=nan(1,numel(selected_layers));
for i=1:length(selected_layers)
    [idx(i),~]=find_layer_idx(layers,selected_layers{i});
end

idx(isnan(idx))=[];

layers_to_split=layers(idx);

layers(idx)=[];

layers_sp=[];

for ilay=1:numel(layers_to_split)
    new_layers=layers_to_split(ilay).split_layer();
    new_layers.load_echo_logbook_db();
    layers_sp=[layers_sp new_layers];
end

if id>0
    layers_sp_sorted=layers_sp.sort_per_survey_data();
    
    layers_sp_out=[];
    
    for icell=1:length(layers_sp_sorted)
        layers_sp_out=[layers_sp_out shuffle_layers(layers_sp_sorted{icell},'multi_layer',-1)];
    end
else
    
    layers_sp_out=layers_sp;
end

%layers_sp_out=reorder_layers_time(layers_sp_out);
id_lay=layers_sp_out(end).Unique_ID;

layers=[layers layers_sp_out];
%layers=reorder_layers_time(layers);
set_esp3_prop('layers',layers);

if contains(layer.Unique_ID,IDs)
    [idx,~]=find_layer_idx(layers,id_lay);
    layer=layers(idx);
    
    set_current_layer(layer);
    clear_regions(main_figure,{},{});
    loadEcho(main_figure);
else
    update_tree_layer_tab(main_figure);
end

end



function open_selected_callback(src,evt,main_figure,IDs)

layers=get_esp3_prop('layers');
layer=get_current_layer();


if numel(IDs)>1
    return;
end

if ~isempty(IDs)
    ID=IDs(1);
    
    if strcmp(layer.Unique_ID,ID)
        return;
    end
    [idx,~]=find_layer_idx(layers,ID);
    set_esp3_prop('layers',layers);
    set_current_layer(layers(idx));
    check_saved_bot_reg(main_figure);
    loadEcho(main_figure);
    
end
end



function merge_selected_callback(src,evt,main_figure,IDs)
layers=get_esp3_prop('layers');
layer=get_current_layer();
selected_layers=IDs;

if isempty(layer)
    return;
end

if isempty(selected_layers)
    return;
end

idx=nan(1,numel(selected_layers));
for i=1:length(selected_layers)
    [idx(i),~]=find_layer_idx(layers,selected_layers{i});
end

idx(isnan(idx))=[];
layers_to_shuffle=layers(idx);

layers(idx)=[];
new_lays=shuffle_layers(layers_to_shuffle,'multi_layer',-1);
layers_out=[layers new_lays];
%layers_out=reorder_layers_time(layers_out);
set_esp3_prop('layers',layers_out);

if contains(layer.Unique_ID,IDs)
    set_current_layer(new_lays(1));
    clear_regions(main_figure,{},{});
    loadEcho(main_figure);
else
    update_tree_layer_tab(main_figure);
end
end
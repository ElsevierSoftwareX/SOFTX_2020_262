function update_tree_layer_tab(main_figure,varargin)

if ~isdeployed()
    disp('Updating layer_tree');
end

if ~isappdata(main_figure,'Layer_tree_tab')
    opt_panel=getappdata(main_figure,'option_tab_panel');
    load_tree_layer_tab(main_figure,opt_panel);
    return;
end

iconpath = fullfile(whereisEcho(),'icons');

layers_curr=get_esp3_prop('layers');
layer=get_current_layer();
layer_tree_tab_comp=getappdata(main_figure,'Layer_tree_tab');

t_start=nan(1,numel(layers_curr));
for i=1:numel(layers_curr)
    [t_start(i),~]=layers_curr(i).get_time_bounds()   ;
end
[~,idx_sort]=sort(t_start);
layers=layers_curr(idx_sort);
layer_tree_tab_comp.root_node.removeAllChildren;
selNode=[];

if ~isempty(varargin)
    layer_tree_tab_comp.sort_method=varargin{1};
end

if ~isempty(layers)
    switch layer_tree_tab_comp.sort_method
        case 'folder'
            [filenames,layer_IDs]=list_files_layers(layers);
            [folder_lays,filenames_lays,~]=cellfun(@fileparts,filenames,'UniformOutput',0);
            [folder_unique,~,idx_fold]=unique(folder_lays,'stable');
            
            for ifold=1:length(folder_unique)
                
                %survey_data=get_survey_data_from_db(folder_unique{ifold});
                
                newNode = uitreenode('v0',[],folder_unique{ifold}, fullfile(iconpath,'book_link.gif'), false);
                userdata.level='folder';
                [userdata.ids,~,idx_lay]=unique(layer_IDs(idx_fold==ifold),'stable');
                userdata.files=filenames_lays(idx_fold==ifold);
                newNode.UserData=userdata;
                
                for ilay=1:length(userdata.ids)
                    [idx,~]=find_layer_idx(layers,userdata.ids{ilay});
                    layers_Str_comp=list_layers(layers(idx));
                    newlNode = uitreenode('v0',[],layers_Str_comp, fullfile(iconpath,'layer_icon.gif'), false);
                    userdatal.level='layer';
                    userdatal.ids=userdata.ids{ilay};
                    
                    userdatal.files=userdata.files(idx_lay==ilay);
                    newlNode.UserData=userdatal;
                    newNode.add(newlNode);
                    if strcmp(layer.Unique_ID,userdatal.ids)
                        selNode=newlNode;
                    end
                    for ifile=1:length(userdatal.files)
                        newfNode = uitreenode('v0',[],userdatal.files{ifile}, fullfile(iconpath,'pageicon.gif'), true);
                        userdataf.level='file';
                        userdataf.ids=userdata.ids{ilay};
                        userdataf.files=userdatal.files{ifile};
                        newfNode.UserData=userdataf;
                        newlNode.add(newfNode);
                    end
                end
                layer_tree_tab_comp.root_node.add(newNode);
            end
            
        case 'surveydata'
            
            [layer_out_cell,idx_lay_cell]=layers.sort_per_survey_data('Voyage','SurveyName');
            layer_IDs={layers(:).Unique_ID};
            
            for isurv=1:length(layer_out_cell)
                
                surv_data=layer_out_cell{isurv}(1).get_survey_data();
                if ~isempty(surv_data)
                    if ~isempty(surv_data.SurveyName)||~isempty(surv_data.Voyage)
                        disp_str=sprintf('Voyage: %s Survey: %s',surv_data.Voyage,surv_data.SurveyName);
                    else
                        disp_str='Layers without voyage metadata';
                    end
                else
                    disp_str='Layers without voyage metadata';
                end
                
                newNode = uitreenode('v0',[],disp_str, fullfile(iconpath,'book_link.gif'), false);
                userdata.level='folder';
                [userdata.ids,~,idx_lay]=unique(layer_IDs(idx_lay_cell{isurv}),'stable');
                userdata.files=list_files_layers(layer_out_cell{isurv});
                newNode.UserData=userdata;
                
                for ilay=1:length(userdata.ids)
                    [idx,~]=find_layer_idx(layers,userdata.ids{ilay});
                    layers_Str_comp=list_layers(layers(idx));
                    newlNode = uitreenode('v0',[],layers_Str_comp, fullfile(iconpath,'layer_icon.gif'), false);
                    userdatal.level='layer';
                    userdatal.ids=userdata.ids{ilay};
                    
                    userdatal.files=list_files_layers(layers(idx));
                    newlNode.UserData=userdatal;
                    newNode.add(newlNode);
                    if strcmp(layer.Unique_ID,userdatal.ids)
                        selNode=newlNode;
                    end
                    for ifile=1:length(userdatal.files)
                        newfNode = uitreenode('v0',[],userdatal.files{ifile}, fullfile(iconpath,'pageicon.gif'), true);
                        userdataf.level='file';
                        userdataf.ids=userdata.ids{ilay};
                        userdataf.files=userdatal.files{ifile};
                        newfNode.UserData=userdataf;
                        newlNode.add(newfNode);
                    end
                end
                layer_tree_tab_comp.root_node.add(newNode);
            end
            
    end
end
layer_tree_tab_comp.tree_h.setRoot(layer_tree_tab_comp.root_node);

if ~isempty(selNode)
    %set(layer_tree_tab_comp.tree_h, 'NodeSelectedCallback', '');
    layer_tree_tab_comp.tree_h.setSelectedNode(selNode);
    %layer_tree_tab_comp.tree_h.expand(selNode);
end
layer_tree_tab_comp.tree_h.expand(layer_tree_tab_comp.root_node);
%drawnow;
%set(layer_tree_tab_comp.tree_h, 'NodeSelectedCallback', {@nodeSelected, main_figure});
setappdata(main_figure,'Layer_tree_tab',layer_tree_tab_comp);

end
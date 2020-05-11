function create_context_menu_track(main_figure,hfig,line)
context_menu=uicontextmenu(hfig);
uimenu(context_menu,'Label','Load/Display','Callback',{@activate_line_callback,main_figure,hfig});
uimenu(context_menu,'Label','Export Track to CSV','Callback',{@export_track_callback,hfig});
for i=1:length(line)
    line(i).UIContextMenu=context_menu;
end
end



function activate_line_callback(~,~,main_figure,hfig,idx)
layers=get_esp3_prop('layers');

idx_lines=getappdata(hfig,'Idx_select');
obj=getappdata(hfig,'Map_input');

files={};

for id=1:length(idx_lines)
    files=[files obj.Filename{idx_lines(id)}];
end


if~isempty(layers)
    [idx,found]=layers.find_layer_idx_files(files);
else
    found=0;
end

if any(found)
    layer=layers(idx(1));
    set_current_layer(layer);
    loadEcho(main_figure);
else
    war_str='We cannot find the transect(s) you are pointing at... Do you want to open it/them?';
     choice=question_dialog_fig(main_figure,'',war_str);
    % Handle response
    switch choice
        case 'Yes'
            open_file([],[],files,main_figure);
        case 'No'
            
        otherwise
            return;
    end
    
end

end

function export_track_callback(~,~,hfig)

idx_lines=getappdata(hfig,'Idx_select');
obj=getappdata(hfig,'Map_input');

new_struct.lat=[];
new_struct.long=[];
new_struct.mat_time=[];

for id=1:length(idx_lines)
    new_struct.lat=[new_struct.lat obj.Lat{idx_lines(id)}];
    new_struct.long=[new_struct.long obj.Long{idx_lines(id)}];
    new_struct.mat_time=[new_struct.mat_time obj.Time{idx_lines(id)}];
end
new_struct.long(new_struct.lon>180)=new_struct.long(new_struct.lon>180)-360;

[path,file,~]=fileparts(obj.Filename{idx_lines(1)}{1});

[filename, pathname] = uiputfile('*_track.csv',...
    'Save track as csv file',...
    fullfile(path,[file '_track.csv']));

if isequal(filename,0) || isequal(pathname,0)
    return;
end


T = struct2table(new_struct);

writetable(T,fullfile(pathname,filename));

end



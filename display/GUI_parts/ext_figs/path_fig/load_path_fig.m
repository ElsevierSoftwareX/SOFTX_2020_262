
function path_fig=load_path_fig(~,~,main_fig)

app_path=get_esp3_prop('app_path');

app_path_main=whereisEcho();
icon=get_icons_cdata(fullfile(app_path_main,'icons'));

path_fields = flipud(fieldnames(app_path));
nb_elt = numel(path_fields);
gui_fmt=init_gui_fmt_struct('pixels');

width = gui_fmt.txt_w*3+gui_fmt.box_w+gui_fmt.x_sep*3;
height = gui_fmt.txt_h*(nb_elt+1)+gui_fmt.y_sep*(nb_elt+1);

path_fig = new_echo_figure(main_fig,'Units','Pixels','Position',[200 200 width height],'Resize','off',...
    'Name','Path Options','WindowStyle','modal','Tag','Path_fig');


for ui = 1:numel(path_fields)
    uicontrol(path_fig,gui_fmt.txtStyle,...
    'Position',[gui_fmt.x_sep gui_fmt.y_sep*(ui+1)+gui_fmt.txt_h*(ui) gui_fmt.txt_w gui_fmt.txt_h],...
    'string',app_path.(path_fields{ui}).Path_description,'tooltipstring',app_path.(path_fields{ui}).Path_tooltipstring,...
    'HorizontalAlignment','left');

 edit_box(ui)=uicontrol(path_fig,gui_fmt.edtStyle,...
    'Position',[gui_fmt.x_sep+gui_fmt.txt_w gui_fmt.y_sep*(ui+1)+gui_fmt.txt_h*(ui) gui_fmt.txt_w*2 gui_fmt.txt_h],...
    'string',app_path.(path_fields{ui}).Path_to_folder,...
    'HorizontalAlignment','left',...
    'Callback',{@check_path_callback,path_fig},'tag',path_fields{ui});

uicontrol(path_fig,gui_fmt.pushbtnStyle,...
    'pos',[gui_fmt.x_sep*2+gui_fmt.txt_w*3 gui_fmt.y_sep*(ui+1)+gui_fmt.txt_h*(ui) gui_fmt.box_w gui_fmt.txt_h],...
    'Cdata',icon.folder,...
    'BackgroundColor','white','callback',{@select_folder_callback,path_fig, edit_box(ui)},'Tag',app_path.(path_fields{ui}).Path_description);
    
end

%%%Save
uicontrol(path_fig,gui_fmt.pushbtnStyle,...
    'string','Save','pos',[gui_fmt.x_sep*2+gui_fmt.txt_w*2-gui_fmt.button_w gui_fmt.y_sep gui_fmt.button_w gui_fmt.button_h],...
    'TooltipString', 'Save Path',...
    'HorizontalAlignment','left','callback',{@validate_path,path_fig});

setappdata(path_fig,'AppPath_temp',app_path);

end

function check_path_callback(src,~,path_fig)
app_path=getappdata(path_fig,'AppPath_temp');
new_path=get(src,'string');
if isfolder(new_path)||strcmp(src.Tag,'cvs_root')
    app_path.(src.Tag).Path_to_folder=new_path;
else
    set(src,'string',app_path.(src.Tag).Path_to_folder);
end
setappdata(path_fig,'AppPath_temp',app_path);
end

function select_folder_callback(src,~,path_fig,edit_box)
path_ori=get(edit_box,'string');
new_path = uigetdir(path_ori,sprintf('Select %s',src.Tag));
if new_path~=0
    set(edit_box,'string',new_path);
end
check_path_callback(edit_box,[],path_fig);
end

function validate_path(~,~,path_fig)

app_path=getappdata(path_fig,'AppPath_temp');

set_esp3_prop('app_path',app_path);

write_config_path_to_xml(app_path);

close(path_fig);
end
function save_echo(varargin)

p = inputParser;

addParameter(p,'path_echo','',@ischar);
addParameter(p,'fileN','',@ischar);
addParameter(p,'cid','main',@ischar);
addParameter(p,'vis','on',@ischar);
parse(p,varargin{:});

esp3_obj=getappdata(groot,'esp3_obj');

main_figure=esp3_obj.main_figure;
curr_disp=esp3_obj.curr_disp;

layer_obj=esp3_obj.get_layer();
if isempty(layer_obj)||isempty(esp3_obj.main_figure)
    return;
end

cid = p.Results.cid;

if isempty(cid)
    cid = curr_disp.ChannelID;
end

Alphamap = get_alphamap(esp3_obj);
% 

[echo_obj_existing,trans_obj,]=get_axis_from_cids(main_figure,{cid});

echo_obj = echo_disp_cl([],...
'cmap',curr_disp.Cmap,'visible_main',p.Results.vis,...
'link_ax',true,...
'YDir',echo_obj_existing.main_ax.YDir,...
'geometry_x',echo_obj_existing.echo_usrdata.geometry_x,...
'geometry_y',echo_obj_existing.echo_usrdata.geometry_y,...
'pos_in_parent',[0 0 1 0.95]);

[dr,dp,up] =echo_obj.display_echogram(trans_obj,...
            'curr_disp',curr_disp,...
            'Fieldname',curr_disp.Fieldname,...
            'x',echo_obj_existing.echo_usrdata.Idx_pings,...
            'y',echo_obj_existing.echo_usrdata.Idx_r,...
            'off_disp',true,...
            'force_update',true);
new_fig = echo_obj.get_parent_figure();
new_fig.Alphamap = Alphamap;

echo_obj.main_ax.XLim = echo_obj_existing.echo_usrdata.xlim;
echo_obj.main_ax.YLim = echo_obj_existing.echo_usrdata.ylim;
echo_obj.update_echo_grid(trans_obj,'curr_disp',curr_disp);
echo_obj.display_echo_bottom(trans_obj,'curr_disp',curr_disp);
echo_obj.display_echo_regions(trans_obj,'curr_disp',curr_disp);
echo_obj.set_echo_alphamap(trans_obj,'curr_disp',curr_disp);

layers_Str=list_layers(layer_obj,'nb_char',80);
title(echo_obj.main_ax,sprintf('%s : %s',deblank(trans_obj.Config.ChannelID),layers_Str{1}),'interpreter','none','color','k');

% size_max = get(0, 'MonitorPositions');
% pos_main=getpixelposition(main_figure);
% [~,id_screen]=nanmin(abs(size_max(:,1)-pos_main(1)));
% new_fig.Position = size_max(id_screen,:).*[1 1 0.9 0.9];

fileN = p.Results.fileN;
path_echo = p.Results.path_echo;

switch fileN
    case '-clipboard'
        print(new_fig,'-clipboard','-dbitmap');
        %hgexport(new_fig,'-clipboard');
        delete(new_fig);
        warndlg_perso(main_figure,'Done','Echogram copied to clipboard...');
        
    otherwise
        if isempty(path_echo)
            path_echo=fullfile(fileparts(layer.Filename{1}),'esp3_echo');
        end
        
        if ~isfolder(path_echo)
            mkdir(path_echo);
        end
        
        if isempty(fileN)
            fileN=generate_valid_filename(sprintf('%s_%s.png',layers_Str{1},layer.ChannelID{idx}));
        end
        
        if ~isfolder(path_echo)
            mkdir(path_echo);
        end
        
        print(new_fig,fullfile(path_echo,fileN),'-dpng','-r300');
        
        echo_db_file = fullfile(path_echo,'echo_db.db');
        add_echo_to_echo_db(echo_db_file,fullfile(path_echo,fileN),layer.Filename,layer.ChannelID{idx},layer.Frequencies(idx));
        
        if strcmpi(vis,'on')
            warndlg_perso(main_figure,'Done','Finished, Echogram has been saved... Check it and close the figure, otherwise, get a screenshot of the new figure...');
        end
end


end
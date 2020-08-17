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

if isempty(layer_obj)
    return;
end

cid = p.Results.cid;

if isempty(cid)
    cid = curr_disp.ChannelID;
end

Alphamap = get_alphamap(esp3_obj);
% 

[echo_obj_existing,trans_obj,~,~]=get_axis_from_cids(main_figure,{cid});

if isempty(echo_obj_existing)
    [trans_obj,~]=layer_obj.get_trans(cid);
    if isempty(trans_obj)
        return;
    end
   ydir = curr_disp.YDir;
   gx = 'pings';
   gy = 'depth';
   idx_pings = 1:numel(trans_obj.Time);
   idx_r = (1:numel(trans_obj.Range));
else
   ydir = echo_obj_existing.main_ax.YDir;
   gx = echo_obj_existing.echo_usrdata.geometry_x;
   gy = echo_obj_existing.echo_usrdata.geometry_y;
   idx_pings = echo_obj_existing.echo_usrdata.Idx_pings;
   idx_r = echo_obj_existing.echo_usrdata.Idx_r;
end


echo_obj = echo_disp_cl([],...
'visible_fig',p.Results.vis,...
'cmap',curr_disp.Cmap,...
'add_colorbar',strcmpi(curr_disp.DispColorbar,'on'),...
'link_ax',true,...
'YDir',ydir,...
'geometry_x',gx,...
'geometry_y',gy,...
'pos_in_parent',[0.05 0.05 0.9 0.88]);

[dr,dp,up] =echo_obj.display_echogram(trans_obj,...
            'curr_disp',curr_disp,...
            'Fieldname',curr_disp.Fieldname,...
            'x',idx_pings,...
            'y',idx_r,...
            'force_update',true);
        
new_fig = echo_obj.get_parent_figure();
new_fig.Alphamap = Alphamap;

if ~isempty(echo_obj_existing)
    x_lim = echo_obj_existing.echo_usrdata.xlim;
    y_lim = echo_obj_existing.echo_usrdata.ylim;
else
    x_lim=[nanmin(echo_obj.echo_surf.XData(:)) nanmax(echo_obj.echo_surf.XData(:))];
    y_lim=[nanmin(echo_obj.echo_surf.YData(:)) nanmax(echo_obj.echo_surf.YData(:))];
end

echo_obj.main_ax.XLim = x_lim;
echo_obj.main_ax.YLim = y_lim;

echo_obj.update_echo_grid(trans_obj,'curr_disp',curr_disp);
echo_obj.display_echo_bottom(trans_obj,'curr_disp',curr_disp);
echo_obj.display_echo_regions(trans_obj,'curr_disp',curr_disp);
echo_obj.set_echo_alphamap(trans_obj,'curr_disp',curr_disp);

layers_Str=list_layers(layer_obj,'nb_char',80);
title(echo_obj.main_ax,sprintf('%s : %s\n',deblank(trans_obj.Config.ChannelID),layers_Str{1}),'interpreter','none','color','k');

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
            path_echo=fullfile(fileparts(layer_obj.Filename{1}),'esp3_echo');
        end
        
        if ~isfolder(path_echo)
            mkdir(path_echo);
        end
        
        if isempty(fileN)
            fileN=generate_valid_filename(sprintf('%s_%s.png',layers_Str{1},trans_obj.Config.ChannelID));
        end
        
        if ~isfolder(path_echo)
            mkdir(path_echo);
        end
        
        print(new_fig,fullfile(path_echo,fileN),'-dpng','-r300');
        
        echo_db_file = fullfile(path_echo,'echo_db.db');
        add_echo_to_echo_db(echo_db_file,fullfile(path_echo,fileN),layer_obj.Filename,trans_obj.Config.ChannelID,trans_obj.Config.Frequency);
        
        if strcmpi(p.Results.vis,'on')
            warndlg_perso(main_figure,'Done','Finished, Echogram has been saved... Check it and close the figure, otherwise, get a screenshot of the new figure...');
        end
end


end
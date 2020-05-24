function load_secondary_freq_win(main_figure,rotate)

secondary_freq=init_secondary_axes_struct();

curr_disp=get_esp3_prop('curr_disp');
if curr_disp.DispSecFreqs<=0
    setappdata(main_figure,'Secondary_freq',secondary_freq);
    return;
end
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

if isempty(layer)
    setappdata(main_figure,'Secondary_freq',secondary_freq);
    return;
end

new=0;
secondary_freq=getappdata(main_figure,'Secondary_freq');

if isempty(secondary_freq)
    new=1;
else
    if isempty(secondary_freq.axes)
        new=1;
    end
end

if new
    switch curr_disp.DispSecFreqsOr
        case 'horz'
            fig_pos=[0.1 0.1 0.3 0.8];
        case 'vert'
            fig_pos=[0.1 0.1 0.8 0.3];
    end
else
    set(secondary_freq.fig,'units','norm');
    fig_pos=get(secondary_freq.fig,'Position');
    if rotate
        fig_pos=[fig_pos(1) fig_pos(2) fig_pos(4) fig_pos(3)];
    end
end

if new==0
    secondary_freq=getappdata(main_figure,'Secondary_freq');
    
    delete(secondary_freq.link_props_top_ax_internal);
    delete(secondary_freq.link_props_side_ax_internal);
    delete(secondary_freq.axes);
    delete(secondary_freq.side_ax);
    delete(secondary_freq.top_ax);
    delete(secondary_freq.echoes);
    
    if rotate>0
        fig_pos = get_dlg_position(main_figure,fig_pos, secondary_freq.fig.Units,'other');
        set(secondary_freq.fig,'units','norm');
        set(secondary_freq.fig,'Position',fig_pos);
        
    end
    
else
    secondary_freq.fig=new_echo_figure(main_figure,'Position',fig_pos,'Units','normalized',...
        'Name','All Channels','CloseRequestFcn',@rm_Secondary_freq,'Tag','Secondary_freq_win','WhichScreen','other');
end
%% Install mouse pointer manager in figure
iptPointerManager( secondary_freq.fig);


nb_chan=numel(curr_disp.SecChannelIDs);

if nb_chan==0
    curr_disp.SecChannelIDs{1}=layer.ChannelID{1};
    curr_disp.SecFreqs(1)=layer.Frequencies(1);
end

secondary_freq.axes=gobjects(1,nb_chan);
secondary_freq.top_ax=gobjects(1,nb_chan);
secondary_freq.side_ax=gobjects(1,nb_chan);
secondary_freq.echoes=gobjects(1,nb_chan);
secondary_freq.echoes_bt=gobjects(1,nb_chan);
secondary_freq.bottom_plots=gobjects(1,nb_chan);
secondary_freq.names=gobjects(1,nb_chan);
secondary_freq.link_props_side_ax_internal=[];
secondary_freq.link_props_top_ax_internal=[];


EchoType='surface';
user_data.geometry_y='depth';
y_grid_disp='on';


disp_chan=ismember(layer.ChannelID,curr_disp.SecChannelIDs);
checked_state=cell(1,nb_chan);
checked_state(disp_chan)={'on'};
checked_state(~disp_chan)={'off'};

for i=1:nb_chan
    
    switch curr_disp.DispSecFreqsOr
        case 'vert'
            pos=[(i-1)/nb_chan 0 1/nb_chan 1];
        case 'horz'
            pos=[0 1-i/nb_chan 1 1/nb_chan];
    end
    
    user_data.geometry_x='pings';
    
    if strcmpi(curr_disp.DispSecFreqsOr,'vert')||i==1
        vis_top='on';
    else
        vis_top='off';
    end
    
    if strcmpi(curr_disp.DispSecFreqsOr,'horz')||nb_chan==i&& strcmpi(user_data.geometry_y,'depth')
        vis_side='on';
    else
        vis_side='off';
    end
    
    secondary_freq.top_ax(i)=axes(secondary_freq.fig,...
        'Interactions',[],'Toolbar',[],...
        'Units','Normalized','Position',[pos(1) pos(2)+pos(4) pos(3) 0],'Fontweight','Bold',...
        'XTickMode','manual','YTickMode','manual',...
        'Layer','top','XLimMode','manual','YLimMode','manual','XTickLabelRotation',-90,'SortMethod','childorder',...
        'TickLength',[0.005 0.005],'XGrid','on','YGrid','off','ClippingStyle','rectangle','box','on','visible',vis_top,...
        'UserData',user_data,'Tag',curr_disp.SecChannelIDs{i});
    
    secondary_freq.side_ax(i)=axes(secondary_freq.fig,...
        'Interactions',[],'Toolbar',[],...
        'Units','Normalized','Position',[pos(1)+pos(3) pos(2) 0 pos(4)],'Fontweight','Bold',...
        'XTickMode','manual','YTickMode','manual',...
        'Layer','top','XLimMode','manual','YLimMode','manual','XTickLabelRotation',0,'YAxisLocation','left',...
        'SortMethod','childorder',...
        'TickLength',[0.005 0.005],'XGrid','on','YGrid',y_grid_disp,'ClippingStyle','rectangle','box','on','visible',vis_side,...
        'UserData',user_data,'Tag',curr_disp.SecChannelIDs{i});
    
    secondary_freq.axes(i)=axes(secondary_freq.fig,...
        'Interactions',[],'Toolbar',[],...
        'Units','Normalized','Position',pos,'Fontweight','Bold',...
        'XTickMode','manual','YTickMode','manual',...
        'nextplot','add','Layer','top','XLimMode','manual','YLimMode','manual','XAxisLocation','top','XTickLabelRotation',-90,...
        'SortMethod','childorder',...
        'TickLength',[0.005 0.005],'XGrid','on','YGrid',y_grid_disp,'ClippingStyle','rectangle','box','on',...
        'UserData',user_data,'XTickLabel',{},'YTickLabel',{},'Tag',curr_disp.SecChannelIDs{i});
    
    
    if  strcmpi(user_data.geometry_y,'depth')
        secondary_freq.side_ax(i).YAxis.TickLabelFormat  = '%g m';
    end
    
    echo_init=zeros(2,2);
    curr_disp=get_esp3_prop('curr_disp');
    
    %alpha_prop='texturemap';
    alpha_prop='flat';
    %alpha_prop_bt='texturemap';
    alpha_prop_bt='flat';
    
    usrdata=init_echo_usrdata();
    
    
    secondary_freq.echoes(i)=pcolor(secondary_freq.axes(i),echo_init);
    set(secondary_freq.echoes(i),'Facealpha',alpha_prop,'FaceColor',alpha_prop,'LineStyle','none','tag',curr_disp.SecChannelIDs{i},'AlphaDataMapping','direct','UserData',usrdata);
    secondary_freq.echoes_bt(i)=pcolor(secondary_freq.axes(i),zeros(size(echo_init),'uint8'));
    set(secondary_freq.echoes_bt(i),'Facealpha',alpha_prop_bt,'FaceColor','k','LineStyle','none','tag','bad_transmits','AlphaDataMapping','direct');
    
    secondary_freq.names(i)=text(secondary_freq.axes(i),10,15,sprintf('%.0fkHz',curr_disp.SecFreqs(i)/1e3),'Units','Pixel','Fontweight','Bold','Fontsize',16,'ButtonDownFcn',{@change_cid,main_figure},'Tag',curr_disp.SecChannelIDs{i},'UserData',curr_disp.SecChannelIDs{i});
    secondary_freq.bottom_plots(i)=plot(secondary_freq.axes(i),nan,nan,'tag','bottom');
    
end


if curr_disp.DispSecFreqsWithOffset
    c='on';
else
    c='off';
end

context_menu=uicontextmenu(secondary_freq.fig,'Tag','MFContextMenu');
uimenu(context_menu,'Label','Change orientation','Callback',{@change_orientation_callback,main_figure});
uimenu(context_menu,'Label','Save Echogramm','Callback',{@save_sec_echo_callback,main_figure,'file'});
uimenu(context_menu,'Label','Copy Echogramm to clipboard','Callback',{@save_sec_echo_callback,main_figure,'clipboard'});
uimenu(context_menu,'Label','Display Transducer depth Offset','Callback',{@toggle_offset_callback,main_figure},'separator','on','Checked',c);
chan_menu=uimenu(context_menu,'Label','Channel to display','separator','on');
uimenu(chan_menu,'Label','all', 'Callback',{@set_secondary_channels_cback,main_figure,'all'});

for ifreq=1:numel(layer.ChannelID)
    uimenu(chan_menu,'Label',sprintf('%.0f kHz',layer.Frequencies(ifreq)/1e3),'Checked',checked_state{ifreq},...
        'Callback',{@set_secondary_channels_cback,main_figure,layer.ChannelID{ifreq}});
end
set(secondary_freq.echoes_bt,'UIContextMenu',context_menu);

enterFcn =  @(figHandle, currentPoint)...
    set(figHandle, 'Pointer', 'hand');
iptSetPointerBehavior(secondary_freq.names,enterFcn);

rm_axes_interactions([secondary_freq.axes secondary_freq.top_ax secondary_freq.side_ax]);

setappdata(main_figure,'Secondary_freq',secondary_freq);

uistack(secondary_freq.top_ax,'top');
uistack(secondary_freq.side_ax,'top');

end
function toggle_offset_callback(src,~,main_figure)
checked=get(src,'checked');
switch checked
    case 'on'
        src.Checked='off';
    case'off'
        src.Checked='on';
end

curr_disp=get_esp3_prop('curr_disp');
curr_disp.DispSecFreqsWithOffset=strcmpi(src.Checked,'on');

end



function set_secondary_channels_cback(src,evt,main_figure,tag)
curr_disp=get_esp3_prop('curr_disp');
layer=get_current_layer();

switch tag
    case 'all'
        curr_disp.SecChannelIDs=layer.ChannelID;
    otherwise
        checked=get(src,'checked');
        switch checked
            case 'on'
                if length(curr_disp.SecChannelIDs)==1
                    return;
                end
                curr_disp.SecChannelIDs(strcmp(curr_disp.SecChannelIDs,tag))=[];
                src.Checked='off';
            case'off'
                curr_disp.SecChannelIDs=union(curr_disp.SecChannelIDs,tag);
                src.Checked='on';
        end
end

[idx,~]=find_cid_idx(layer,curr_disp.SecChannelIDs);
curr_disp.SecFreqs=layer.Frequencies(idx);
[~,idx_s]=sort(layer.Frequencies(idx));
curr_disp.SecChannelIDs=curr_disp.SecChannelIDs(idx_s);
curr_disp.SecFreqs=curr_disp.SecFreqs(idx_s);
curr_disp.DispSecFreqs=curr_disp.DispSecFreqs;

end

function change_orientation_callback(~,~,main_figure)
curr_disp=get_esp3_prop('curr_disp');

switch curr_disp.DispSecFreqsOr
    case 'vert'
        curr_disp.DispSecFreqsOr='horz';
    case 'horz'
        curr_disp.DispSecFreqsOr='vert';
end

end

function  change_cid(src,evt,main_figure)

curr_disp=get_esp3_prop('curr_disp');
if ~strcmp(curr_disp.ChannelID,src.UserData)
    curr_disp.ChannelID=src.UserData;
end
end

function save_sec_echo_callback(src,evt,main_figure,tag)

layer=get_current_layer();
if isempty(layer)
    return;
end

switch tag
    case 'clipboard'
        save_echo(main_figure,[],'-clipboard','sec_ax');
        
    otherwise
        [path_tmp,~,~]=fileparts(layer.Filename{1});
        layers_Str=list_layers(layer,'nb_char',80);
        
        [fileN, path_tmp] = uiputfile('*.png',...
            'Save echogram',...
            fullfile(path_tmp,[layers_Str{1} '.png']));
        
        if isequal(path_tmp,0)
            return;
        else
            save_echo(main_figure,path_tmp,fileN,'sec_ax');
        end
end

end

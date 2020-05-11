
function set_alpha_map(main_figure,varargin)

if ~isdeployed
    disp('set_alpha_map')
end
layer=get_current_layer();
if isempty(layer)
    return;
end
curr_disp=get_esp3_prop('curr_disp');
p = inputParser;


addRequired(p,'main_figure',@ishandle);
addParameter(p,'main_or_mini',union({'main','mini'},curr_disp.ChannelID,'stable'));
addParameter(p,'update_bt',1);
addParameter(p,'update_under_bot',1);
addParameter(p,'update_cmap',1);

parse(p,main_figure,varargin{:});

%alpha_map_fig=get(main_figure,'alphamap')%6 elts vector: first: empty, second: under clim(1), third: underbottom, fourth: bad trans, fifth regions, sixth normal]

update_bt=p.Results.update_bt;
update_under_bot=p.Results.update_under_bot;
update_cmap=p.Results.update_cmap;

if~iscell(p.Results.main_or_mini)
    main_or_mini={p.Results.main_or_mini};
else
    main_or_mini=p.Results.main_or_mini;
end

[echo_im_tot,echo_ax_tot,echo_im_bt_tot,trans_obj,~,~]=get_axis_from_cids(main_figure,main_or_mini);

if isempty(echo_im_tot)
    return;
end

min_axis=curr_disp.Cax(1);

for iax=1:length(echo_ax_tot)
    
    echo_im=echo_im_tot(iax);
    echo_ax=echo_ax_tot(iax);
    echo_im_bt=echo_im_bt_tot(iax);
    
    
    data=double(get(echo_im,'CData'));
    xdata=double(get(echo_im,'XData'));
    
    
    xdata_ori=xdata;
    
    idx_pings=echo_im.UserData.Idx_pings;
    
    idx_r=echo_im.UserData.Idx_r(:);
    
    max_val=intmax('uint8');
    prec='uint8';
        
    switch echo_ax_tot(iax).UserData.geometry_y
        case'samples'
            ydata=idx_r+1/2;
        case 'depth'
            ydata=double(get(echo_im,'YData'));
    end
    
    
    if update_under_bot>0
        alpha_map=ones(size(data),prec)*6;
        switch echo_ax_tot(iax).UserData.geometry_y
            case'samples'
                bot_vec_red=trans_obj{iax}.get_bottom_idx(idx_pings);
            case 'depth'
                if curr_disp.DispSecFreqsWithOffset>0
                    bot_vec_red=trans_obj{iax}.get_bottom_depth(idx_pings);
                else
                    bot_vec_red=trans_obj{iax}.get_bottom_range(idx_pings);
                end
        end
        
        idx_bot_red=bsxfun(@le,bot_vec_red,ydata);
        alpha_map(idx_bot_red)=2;
    else
        alpha_map=double(get(echo_im,'AlphaData'));
    end
    
    %alpha_map(:,idx_bad_red)=3;
    
    if update_bt>0
        
        idxBad=find(trans_obj{iax}.Bottom.Tag==0);
        idx_bad_red=find(ismember(idx_pings,idxBad));
        
        data_temp=zeros(size(data),prec);
        data_temp(:,idx_bad_red)=max_val;
        alpha_map_bt=zeros(size(data_temp),'single');
        alpha_map_bt(:,idx_bad_red)=3;
        
        [mask_sp,~]=trans_obj{iax}.Data.get_subdatamat(idx_r,idx_pings,'field','spikesmask');
        
        if~isempty(mask_sp)&&all(size(mask_sp)==size(data_temp))
            data_temp(mask_sp>0)=max_val;
            alpha_map_bt(mask_sp>0)=5;
        end
        
        
        switch echo_im_bt.Type
            case  'image'
                set(echo_im_bt,'XData',xdata_ori,'YData',ydata,'CData',data_temp,'AlphaData',(alpha_map_bt));
            case 'surface'
                set(echo_im_bt,'XData',xdata_ori,'YData',ydata,'CData',data_temp,'ZData',zeros(size(data_temp),'uint8'),'AlphaData',(alpha_map_bt));
        end
        
    end
    
    if update_cmap>0
        alpha_map(data<min_axis|isnan(data))=1;
        if strcmp(echo_ax.Tag,'main')
            set(echo_ax,'CLim',curr_disp.Cax);
        end
    end
    if update_cmap>0||update_under_bot>0
        set(echo_im,'AlphaData',single(alpha_map));
    end
end

end
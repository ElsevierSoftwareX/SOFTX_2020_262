function upped=update_axis(main_figure,new,varargin)

if ~isdeployed
    disp('update_axis')
end
layer=get_current_layer();
if isempty(layer)
    return;
end
curr_disp=get_esp3_prop('curr_disp');
p = inputParser;

%profile on;
addRequired(p,'main_figure',@ishandle);
addRequired(p,'new',@isnumeric);
addParameter(p,'main_or_mini',union({'main','mini'},curr_disp.ChannelID,'stable'));
addParameter(p,'force_update',0);

parse(p,main_figure,new,varargin{:});

if~iscell(p.Results.main_or_mini)
    main_or_mini={p.Results.main_or_mini};
else
    main_or_mini=p.Results.main_or_mini;
end
axes_panel_comp=getappdata(main_figure,'Axes_panel');
mini_axes_comp=getappdata(main_figure,'Mini_axes');

[echo_im_tot,echo_ax_tot,~,trans_obj_tot,~,cids]=get_axis_from_cids(main_figure,main_or_mini);

upped=zeros(1,numel(echo_im_tot));
xlim_sec=[nan nan];
ylim_sec=[nan nan];
idx_sec=[];
for iax=1:length(echo_ax_tot)
    
    echo_im=echo_im_tot(iax);
    echo_ax=echo_ax_tot(iax);
    trans_obj=trans_obj_tot{iax};
    pings=trans_obj.get_transceiver_pings();
    samples=trans_obj.get_transceiver_samples();
    range_t=trans_obj.get_transceiver_range();
    nb_pings=length(pings);
    nb_samples=length(samples);
    
    
    switch main_or_mini{iax}
        case 'main'
            off_disp=0;
            if new==0
                x=double(get(echo_ax,'xlim'));
                y=double(get(echo_ax,'ylim'));
            else
                x=[-inf inf];
                y=[-inf inf];
                u=findobj(echo_ax,'Tag','SelectLine','-or','Tag','SelectArea');
                delete(u);
            end
           
            set(axes_panel_comp.axes_panel,'Title',...
            sprintf('%s: %.0f kHz %s',curr_disp.Type,curr_disp.Freq/1e3,cids{iax}),'UserData',curr_disp.ChannelID)
            delete(axes_panel_comp.listeners);
            axes_panel_comp.listeners=[];
            clear_lines(axes_panel_comp.main_axes);
            
        case 'mini'
            
            off_disp=0;
            y=[1 nb_samples];
            x=[1 nb_pings];
        otherwise
            off_disp=curr_disp.DispSecFreqsWithOffset;
            x=double(get(axes_panel_comp.main_axes,'xlim'));
            
            dr=nanmean(diff(range_t));
            y1=(curr_disp.R_disp(1)-range_t(1))/dr;
            y2=(curr_disp.R_disp(2)-range_t(1))/dr;
            y=[y1 y2];
    end
    
    if ~isempty(echo_im)
        struct_temp=[];
        struct_temp.ChannelID=cids{iax};
        struct_temp.Freq=layer.Frequencies(strcmpi(layer.ChannelID,cids{iax}));
        struct_temp.DispSpikes=curr_disp.DispSpikes;
        struct_temp.EchoQuality=curr_disp.EchoQuality;
        struct_temp.EchoType=curr_disp.EchoType;
        struct_temp.Disp_dy_dx=curr_disp.Disp_dy_dx;
        [dr,dp,upped(iax)]=layer.display_layer(struct_temp,curr_disp.Fieldname,echo_ax,echo_im,x,y,off_disp,p.Results.force_update);  
    end
    
    
    switch main_or_mini{iax}
        case 'main'
            str_subsampling=sprintf('SubSampling: [%.0fx%.0f]',dr,dp);
            info_panel_comp=getappdata(main_figure,'Info_panel');
            if dr>1||dp>1
                set(info_panel_comp.display_subsampling,'String',str_subsampling,'ForegroundColor',[0.5 0 0],'Fontweight','bold');
            else
                set(info_panel_comp.display_subsampling,'String',str_subsampling,'ForegroundColor',[0 0.5 0],'Fontweight','normal');
            end
            
            if diff(echo_ax_tot(iax).UserData.xlim)>0
                echo_ax_tot(iax).XLim=echo_ax_tot(iax).UserData.xlim;
            end
            if diff(echo_ax_tot(iax).UserData.ylim)>0
                echo_ax_tot(iax).YLim=echo_ax_tot(iax).UserData.ylim;
            end
            ylim_ax=get(axes_panel_comp.main_axes,'YLim');
            
            if new
                if ~isempty(ylim_ax)
                    if strcmpi(axes_panel_comp.main_axes.UserData.geometry_y,'samples')
                        curr_disp.R_disp=range_t(round(ylim_ax));
                    else
                        curr_disp.R_disp=ylim_ax;
                    end
                else
                    curr_disp.R_disp=[range_t(1) range_t(end)];
                end
                
                
            end
            axes_panel_comp.listeners=addlistener(axes_panel_comp.main_axes,'YLim','PostSet',@(src,envdata)listenYLim(src,envdata,main_figure));
            setappdata(main_figure,'Axes_panel',axes_panel_comp);
        case 'mini'

             if diff(echo_ax_tot(iax).UserData.xlim)>0
                echo_ax_tot(iax).XLim=echo_ax_tot(iax).UserData.xlim;
            end
            if diff(echo_ax_tot(iax).UserData.ylim)>0
                echo_ax_tot(iax).YLim=echo_ax_tot(iax).UserData.ylim;
            end
            x_lim=get(axes_panel_comp.main_axes,'xlim');
            y_lim=get(axes_panel_comp.main_axes,'ylim');
            v1 = [x_lim(1) y_lim(1);x_lim(2) y_lim(1);x_lim(2) y_lim(2);x_lim(1) y_lim(2)];
            f1=[1 2 3 4];
            set(mini_axes_comp.patch_obj,'Faces',f1,'Vertices',v1);
            xd=get(axes_panel_comp.main_echo,'xdata');
            yd=get(axes_panel_comp.main_echo,'ydata');
            
            v2 = [nanmin(xd) nanmin(yd);nanmax(xd) nanmin(yd);nanmax(xd) nanmax(yd);nanmin(xd) nanmax(yd)];
            f2=[1 2 3 4];
            set(mini_axes_comp.patch_lim_obj,'Faces',f2,'Vertices',v2);
            
        otherwise
            if diff(echo_ax_tot(iax).UserData.ylim)>0&&diff(echo_ax_tot(iax).UserData.ylim)>0
                idx_sec=iax;
                xlim_sec=[nanmin(xlim_sec(1),echo_ax_tot(iax).UserData.xlim(1))...
                    nanmax(xlim_sec(2),echo_ax_tot(iax).UserData.xlim(2))];
               ylim_sec=[nanmin(ylim_sec(1),echo_ax_tot(iax).UserData.ylim(1))...
                    nanmax(ylim_sec(2),echo_ax_tot(iax).UserData.ylim(2))];
            end
            

    end     
end

if ~isempty(idx_sec)
    if any(echo_ax_tot(idx_sec).XLim~=xlim_sec)&&xlim_sec(2)>xlim_sec(1)
        echo_ax_tot(idx_sec).XLim=xlim_sec;
    end
    if any(echo_ax_tot(idx_sec).YLim~=ylim_sec)&&ylim_sec(2)>ylim_sec(1)
        echo_ax_tot(idx_sec).YLim=ylim_sec;
    end
end


if any(strcmpi(main_or_mini,'main'))
    update_grid(main_figure);
end
if any(strcmpi(main_or_mini,'mini'))
    update_grid_mini_ax(main_figure);
end

update_info_panel([],[],1);
end
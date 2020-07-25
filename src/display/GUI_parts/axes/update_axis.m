function upped=update_axis(main_figure,new,varargin)

if ~isdeployed
    disp('update_axis')
end
layer_obj=get_current_layer();
if isempty(layer_obj)
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

[echo_obj,trans_obj_tot,~,~]=get_axis_from_cids(main_figure,main_or_mini);

upped=zeros(1,numel(echo_obj));
xlim_sec=[nan nan];
ylim_sec=[nan nan];
idx_sec=[];

for iax=1:length(echo_obj)
    
    echo_im=echo_obj.get_echo_surf(iax);
    echo_ax=echo_obj.get_main_ax(iax);
    trans_obj=trans_obj_tot(iax);
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
           
            axes_panel_comp.axes_panel.UserData = curr_disp.ChannelID;
            delete(axes_panel_comp.listeners);
            axes_panel_comp.listeners=[];
            clear_lines(axes_panel_comp.echo_obj.main_ax);
            
        case 'mini'
            
            off_disp=0;
            y=[1 nb_samples];
            x=[1 nb_pings];
        otherwise
            off_disp=curr_disp.DispSecFreqsWithOffset;
            x=double(get(axes_panel_comp.echo_obj.main_ax,'xlim'));
            
            dr=nanmean(diff(range_t));
            y1=(curr_disp.R_disp(1)-range_t(1))/dr;
            y2=(curr_disp.R_disp(2)-range_t(1))/dr;
            y=[y1 y2];
    end
    
    if ~isempty(echo_im)

        [dr,dp,upped(iax)]=echo_obj(iax).display_echogram(trans_obj,...
            'Unique_ID',layer_obj.Unique_ID,...
            'curr_disp',curr_disp,...
            'Fieldname',curr_disp.Fieldname,...
            'x',x,'y',y,...
            'off_disp',off_disp>0,...
            'force_update',p.Results.force_update>0);  
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
            
            if diff(echo_obj(iax).echo_usrdata.xlim)>0
                echo_obj.get_main_ax(iax).XLim=echo_obj(iax).echo_usrdata.xlim;
            end
            if diff(echo_obj(iax).echo_usrdata.ylim)>0
                echo_obj.get_main_ax(iax).YLim=echo_obj(iax).echo_usrdata.ylim;
            end
            ylim_ax=get(axes_panel_comp.echo_obj.main_ax,'YLim');
            
            if new
                if ~isempty(ylim_ax)
                    if strcmpi(axes_panel_comp.echo_obj.echo_usrdata.geometry_y,'samples')
                        curr_disp.R_disp=range_t(round(ylim_ax));
                    else
                        curr_disp.R_disp=ylim_ax;
                    end
                else
                    curr_disp.R_disp=[range_t(1) range_t(end)];
                end
                
                
            end
            axes_panel_comp.listeners=addlistener(axes_panel_comp.echo_obj.main_ax,'YLim','PostSet',@(src,envdata)listenYLim(src,envdata,main_figure));
            setappdata(main_figure,'Axes_panel',axes_panel_comp);
        case 'mini'

             if diff(echo_obj(iax).echo_usrdata.xlim)>0
                echo_obj.get_main_ax(iax).XLim=echo_obj(iax).echo_usrdata.xlim;
            end
            if diff(echo_obj(iax).echo_usrdata.ylim)>0
                echo_obj.get_main_ax(iax).YLim=echo_obj(iax).echo_usrdata.ylim;
            end
            
            x_lim=get(axes_panel_comp.echo_obj.main_ax,'xlim');
            y_lim=get(axes_panel_comp.echo_obj.main_ax,'ylim');
            v1 = [x_lim(1) y_lim(1);x_lim(2) y_lim(1);x_lim(2) y_lim(2);x_lim(1) y_lim(2)];
            f1=[1 2 3 4];
            set(mini_axes_comp.patch_obj,'Faces',f1,'Vertices',v1);
            xd=get(axes_panel_comp.echo_obj.echo_surf,'xdata');
            yd=get(axes_panel_comp.echo_obj.echo_surf,'ydata');
            
            v2 = [nanmin(xd) nanmin(yd);nanmax(xd) nanmin(yd);nanmax(xd) nanmax(yd);nanmin(xd) nanmax(yd)];
            f2=[1 2 3 4];
            set(mini_axes_comp.patch_lim_obj,'Faces',f2,'Vertices',v2);
            
        otherwise
            if diff(echo_obj(iax).echo_usrdata.ylim)>0&&diff(echo_obj(iax).echo_usrdata.ylim)>0
                idx_sec=iax;
                xlim_sec=[nanmin(xlim_sec(1),echo_obj(iax).echo_usrdata.xlim(1))...
                    nanmax(xlim_sec(2),echo_obj(iax).echo_usrdata.xlim(2))];
               ylim_sec=[nanmin(ylim_sec(1),echo_obj(iax).echo_usrdata.ylim(1))...
                    nanmax(ylim_sec(2),echo_obj(iax).echo_usrdata.ylim(2))];
            end
            

    end     
end

if ~isempty(idx_sec)
    if any(echo_obj.get_main_ax(idx_sec).XLim~=xlim_sec)&&xlim_sec(2)>xlim_sec(1)
        echo_obj.get_main_ax(idx_sec).XLim=xlim_sec;
    end
    if any(echo_obj.get_main_ax(idx_sec).YLim~=ylim_sec)&&ylim_sec(2)>ylim_sec(1)
        echo_obj.get_main_ax(idx_sec).YLim=ylim_sec;
    end
end

if any(strcmpi(main_or_mini,'mini'))
    update_grid_mini_ax(main_figure);
end

if any(strcmpi(main_or_mini,'main'))
    update_grid(main_figure);
end
update_info_panel([],[],1);
end